with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with c4_messages;
with abb_maps_g;
with vertical_dashboard;
with server_game;

package body Server_Handler is
	package ATIO renames Ada.Text_IO;
	package CM renames c4_messages;
	package VD renames vertical_dashboard;
	
	use type ASU.Unbounded_String;

	procedure Send_All_Players(C4_Game: in SG.C4_Game_Type; P_Buffer: access LLU.Buffer_Type) is
	begin
		for I in 1..SG.Get_Number_Players(C4_Game) loop
			LLU.Send(SG.Get_Client_EP(C4_Game, I),P_Buffer);
		end loop;
	end Send_All_Players;
	
	procedure Column_Error(Column: in out Positive; C4_Game: in SG.C4_Game_Type; Nick: in ASU.Unbounded_String)is
		Move_Ok: Boolean;
		Buffer:	aliased LLU.Buffer_Type(2048);
	begin
		Move_Ok := True;
		if Column > 10 then 
			Move_Ok := False;
			LLU.Reset(Buffer);
			CM.Message_Type'Output(Buffer'Access,CM.MoveReceived);
			Boolean'Output(Buffer'Access,False);
			LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), Buffer'Access); 
		else 
			Move_Ok := True;
		end if;
	end Column_Error;
	
	function Client_Nick_Already_Exists(Games: in ABB_Maps.Map; 
	Client_Nick: in ASU.Unbounded_String) return Boolean is
	Game: SG.C4_Game_Type;
	begin
		if ABB_Maps.Is_Empty(Games) then
			return False;
		else
			Game := ABB_Maps.Get_Value(Games);
			
			return 
				SG.Nick_Duplicated(Game, Client_Nick) or else
				Client_Nick_Already_Exists(ABB_Maps.Get_Left(Games), Client_Nick) or else
				Client_Nick_Already_Exists(ABB_Maps.Get_Right(Games), Client_Nick);
		end if;
	end Client_Nick_Already_Exists;

	procedure Game_With_Break(Games: in ABB_Maps.Map; 
		Game_Key: out ASU.Unbounded_String;
		Game: out SG.C4_Game_Type;
		Found: out Boolean) is
		Game_Aux: SG.C4_Game_Type;
	begin
		if ABB_Maps.Is_Empty(Games) then
			Found := False;
		else
			Game_Key := ABB_Maps.Get_Key(Games);
			Game_Aux := ABB_Maps.Get_Value(Games);
			
			if SG.Get_Number_Players(Game_Aux) /= SG.Get_Max_Players(Game_Aux) then
				Found := True;
				Game := Game_Aux;
			else
				Game_With_Break(ABB_Maps.Get_Left(Games), Game_Key, Game, Found);
				if not Found then
					Game_With_Break(ABB_Maps.Get_Right(Games), Game_Key, Game, Found);
				end if;
			end if;
		end if;
	end Game_With_Break;
		
	procedure Handle_Join(P_Buffer: access LLU.Buffer_Type) is
	Client_EP_Handler: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Nick: ASU.Unbounded_String;
	Game_Key: ASU.Unbounded_String;
	Game: SG.C4_Game_Type; 
	Message: ASU.Unbounded_String;
	Found: Boolean;
	Added_To_Game: Boolean;
	Success: Boolean;
	begin	
		Client_EP_Receive := LLU.End_Point_Type'Input(P_Buffer);
		Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		Nick := ASU.Unbounded_String'Input(P_Buffer);
		Game_Key := ASU.Unbounded_String'Input(P_Buffer);
		
		ATIO.Put_Line(ASU.To_String(Nick) & " is trying to join the game....");
		Added_To_Game := False;
		if Client_Nick_Already_Exists(Map, Nick) then 
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output(P_Buffer, CM.Welcome);
			Boolean'Output(P_Buffer,False);
			ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String("Could not join. Duplicated Nickname"));
			ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String(""));
			LLU.Send(Client_EP_Receive, P_Buffer);
			
			ATIO.Put("Duplicated Nickname");
			ATIO.New_Line;
			
		elsif ASU.Length(Game_Key) /= 0 then
			ABB_Maps.Get(Map,Game_Key,Game,Success);
			if Success then 
				if SG.Get_Number_Players(Game) = SG.Get_Max_Players(Game) then 
					LLU.Reset(P_Buffer.all);
					CM.Message_Type'Output(P_Buffer, CM.Welcome);
					Boolean'Output(P_Buffer,False);
					ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String("Could not join. Game key " & ASU.To_String(Game_Key) & " is full"));
					ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String(""));
					LLU.Send(Client_EP_Receive,P_Buffer);
					
					ATIO.Put_Line("Rejected. Game with key " & ASU.To_String(Game_Key) & " is full");
				else 
					SG.Set_Player_Info(Game,Nick,Client_EP_Handler);
					ABB_Maps.Put(Map,Game_Key,Game);
					
					Added_To_Game := True;
				end if;
			else 
				SG.Set_Player_Info(Game,Nick,Client_EP_Handler);
				ABB_Maps.Put(Map,Game_Key,Game);
				
				Added_To_Game := True;
			end if;	
		else 
			Game_With_Break(Map, Game_Key, Game, Found);
			if Found then
				SG.Set_Player_Info(Game,Nick,Client_EP_Handler);
				ABB_Maps.Put(Map,Game_Key,Game);
			else 
				SG.Set_Player_Info(Game,Nick,Client_EP_Handler);
				Game_Key := Nick;
				ABB_Maps.Put(Map,Game_Key,Game);
			end if;
			ATIO.Put_Line("Joined sucessfully - Game Key:" & ASU.To_String(Game_Key));

			Added_To_Game := True;
		end if;
		
		if Added_To_Game then
		
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output(P_Buffer, CM.Welcome);
			Boolean'Output(P_Buffer,True);
			ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String(""));
			ASU.Unbounded_String'Output(P_Buffer,Game_Key);
			LLU.Send(Client_EP_Receive, P_Buffer);
			
			LLU.Reset(P_Buffer.all);
			CM.Message_Type'Output(P_Buffer, CM.Server);
			ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String("There are" & Natural'Image(SG.Get_Number_Players(Game)) & " /" & Natural'Image(SG.Get_Max_Players(Game))));
			Send_All_Players((Game),P_Buffer);
			
			if SG.Get_Number_Players(Game) = SG.Get_Max_Players(Game) then 
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.StartGame);
				Send_All_Players((Game),P_Buffer);
				
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.Server);
				Message := VD.Dashboard_To_US(SG.Get_Dashboard(Game).all);
				ASU.Unbounded_String'Output(P_Buffer, Message);
				LLU.Send(SG.Get_Client_EP(Game, SG.Get_Current_Turn(Game)), P_Buffer);
				
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.YourTurn);
				LLU.Send(SG.Get_Client_EP(Game, SG.Get_Current_Turn(Game)),P_Buffer);	
			end if;
		end if;
	end Handle_Join;
	
	procedure Handle_Move(P_Buffer: access LLU.Buffer_Type) is
	Winner: Boolean;
	Column: Natural;
	Game_Key: ASU.Unbounded_String;
	C4_Game: SG.C4_Game_Type;
	Nick: ASU.Unbounded_String;
	Value: ASU.Unbounded_String;
	Success: Boolean;
	Message: ASU.Unbounded_String;
	begin
		Column := Natural'Input(P_Buffer);
		Game_Key := ASU.Unbounded_String'Input(P_Buffer);
		
		ABB_Maps.Get(Map,Game_Key,C4_Game,Success);
		if Success then 
			if Column >= 1 and Column <= 10 then 
				VD.Put_Token(SG.Get_Dashboard(C4_Game).all, Column, SG.Get_Current_Turn(C4_Game), Winner);
				LLU.Reset(P_Buffer.all);
				
				ATIO.Put_Line(ASU.To_String(Game_Key) & " - " & ASU.To_String(SG.Get_Client_Name(C4_Game, SG.Get_Current_Turn(C4_Game))) & "'s move:" & Natural'Image(Column) & " - Valid");
				
				if Winner = True then 
					LLU.Reset(P_Buffer.all);
					CM.Message_type'Output(P_Buffer,CM.EndGame);
					ASU.Unbounded_String'Output(P_Buffer,SG.Get_Client_Name(C4_Game, SG.Get_Current_Turn(C4_Game)));
					ASU.Unbounded_String'Output(P_Buffer,VD.Dashboard_To_US(SG.Get_Dashboard(C4_Game).all));
					ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String(""));
					Boolean'Output(P_Buffer,True);
					Send_All_Players(C4_Game,P_Buffer);
					
					ATIO.Put_Line(ASU.To_String(Game_Key) & " - " & ASU.To_String(SG.Get_Client_Name(C4_Game,SG.Get_Current_Turn(C4_Game)) & " has won the game!"));
					
					ABB_Maps.Delete(Map,Game_Key,Success);

				elsif VD.Dashboard_Is_Full(SG.Get_Dashboard(C4_Game).all) then
					LLU.Reset(P_Buffer.all);
					CM.Message_type'Output(P_Buffer,CM.EndGame);
					ASU.Unbounded_String'Output(P_Buffer,ASU.To_Unbounded_String(""));
					ASU.Unbounded_String'Output(P_Buffer,VD.Dashboard_To_US(SG.Get_Dashboard(C4_Game).all));
					ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String(""));
					Boolean'Output(P_Buffer,False);
					Send_All_Players(C4_Game,P_Buffer);
					
					ATIO.Put_Line("The game has finished. Dashboard is full");
					
					ABB_Maps.Delete(Map,Game_Key,Success);
				
				else 
					SG.Next_Turn(C4_Game);
					
					LLU.Reset(P_Buffer.all);
					CM.Message_Type'Output(P_Buffer, CM.Server);
					Message := VD.Dashboard_To_US(SG.Get_Dashboard(C4_Game).all);
					ASU.Unbounded_String'Output(P_Buffer, Message);
					LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), P_Buffer);
					
					LLU.Reset(P_Buffer.all);
					CM.Message_type'Output(p_Buffer,CM.YourTurn);
					LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), P_Buffer);
					
					
					ABB_Maps.Put(Map,Game_Key,C4_Game);
				
				end if;
			else 
				Column_Error(Column, C4_Game, Nick);
				ATIO.Put_Line(ASU.To_String(Game_Key) & " - " & ASU.To_String(SG.Get_Client_Name(C4_Game, SG.Get_Current_Turn(C4_Game))) & "'s move:" & Natural'Image(Column) & " - Invalid");
			end if;
		end if;
	end Handle_Move;
	
	procedure Handle_Logout(P_Buffer: access LLU.Buffer_Type) is 
	Nick: ASU.Unbounded_String;
	Client_EP_Handler: LLU.End_Point_Type;
	Game_Key: ASU.Unbounded_String;
	Game: SG.C4_Game_Type;
	Success: Boolean;
	begin 
		Game_Key := ASU.Unbounded_String'Input(P_Buffer);
		Nick := ASU.Unbounded_String'Input(P_Buffer);
		Client_EP_Handler := LLU.End_Point_Type'Input(P_Buffer);
		ABB_Maps.Get(Map,Game_Key,Game,Success);
		if Success then 
			if SG.Nick_Duplicated(Game,Nick) and SG.EP_Duplicated(Game,Client_EP_Handler) then
				ATIO.Put_Line(ASU.To_String(Nick) & " has left the game");
				LLU.Reset(P_Buffer.all);
				CM.Message_Type'Output(P_Buffer, CM.EndGame);
				ASU.Unbounded_String'Output(P_Buffer, SG.Get_Client_Name(Game, SG.Get_Current_Turn(Game))); 
				ASU.Unbounded_String'Output(P_Buffer, VD.Dashboard_To_US(SG.Get_Dashboard(Game).all));
				ASU.Unbounded_String'Output(P_Buffer, ASU.To_Unbounded_String(""));
				Boolean'Output(P_Buffer,True);
				Send_All_Players((Game), P_Buffer);				
			end if;
		end if;
	end Handle_Logout;
	
	procedure Server_Handler(From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type) is 
		Response: CM.Message_Type;
	begin
		Response := CM.Message_Type'Input(P_Buffer);
		--ATIO.Put_Line(CM.Message_Type'Image(Response) & " received...");
		case Response is
			when CM.Join =>
				Handle_Join(P_Buffer);
				
			when CM.Move =>
				Handle_Move(P_Buffer);
			
			when CM.Logout =>
				Handle_Logout(P_Buffer);
			
			when others =>
				null;
				
			end case;
	end Server_Handler;
end server_handler;
