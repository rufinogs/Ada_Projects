with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;

with vertical_dashboard;
with server_game;
with c4_messages;

procedure c4_server is 
	package ATIO renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package ASU renames Ada.Strings.Unbounded;
	package AE renames Ada.Exceptions;
	package CM renames c4_messages;
	package VD renames vertical_dashboard;
	package SG renames server_game;
	
	use type ASU.Unbounded_String;
	use type CM.Message_Type;
	
	Usage_Error: exception;
	
	N_Args : constant Integer := 1;
	
	procedure Send_All_Players(C4_Game: in SG.C4_Game_Type; P_Buffer: access LLU.Buffer_Type) is
	begin
		for I in 1..SG.Get_Max_Players(C4_Game) loop
			LLU.Send(SG.Get_Client_EP(C4_Game, I),P_Buffer);
		end loop;
	end Send_All_Players;
	
	procedure Send_All_Player_Less_One(C4_Game: in SG.C4_Game_Type; P_Buffer: access LLU.Buffer_Type) is
	begin
		for I in 1..SG.Get_Number_Players(C4_Game) - 1  loop
			LLU.Send(SG.Get_Client_EP(C4_Game,I),P_Buffer); --Buffer'Access);
		end loop;
	end Send_All_Player_Less_One;
	
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
			LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), Buffer'Access); -- ERROR: No estabas obteniendo el EP del jugador al que has cambiado el turno
			ATIO.Put_Line(ASU.To_String(Nick) & "'s move:" & Natural'Image(Column) & " - Invalid");
		else 
			Move_Ok := True;
		end if;
	end Column_Error;
	
	Port: Integer;
	Server_EP: LLU.End_Point_Type;
	Buffer:	aliased LLU.Buffer_Type(2048);
	Client_EP: LLU.End_Point_Type;
	Expired: Boolean;
	C4_Game: SG.C4_Game_Type;
	Nick: ASU.Unbounded_String;
	Winner: Boolean;
	Exists: Boolean;
	Column: Positive;
	Response: CM.Message_type;

	Game_Starts: Boolean;
	
begin
	if ACL.Argument_Count /= N_Args then
		raise Usage_Error;
	end if;
		
	Port := Integer'Value(ACL.Argument(1));

	Server_EP := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Port);
	LLU.Bind(Server_EP);

	ATIO.Put_Line("Listening on port" & Integer'Image(Port) & ":");
	
	loop
		LLU.Reset(Buffer);
		LLU.Receive(Server_EP, Buffer'Access, 10.0, Expired);
		
		if not Expired then 
			Response := CM.Message_type'Input(Buffer'Access);		
			case Response is
				when CM.Join => 
					Game_Starts := False;
					Client_EP := LLU.End_Point_Type'Input(Buffer'Access);
					Nick := ASU.Unbounded_String'Input(Buffer'Access);
			
					ATIO.Put_Line(ASU.To_String(Nick) & " is triying to join a game...");
					
					if Nick = SG.Get_Client_Name(C4_Game,1) then
						LLU.Reset(Buffer);
						CM.Message_Type'Output(Buffer'Access, CM.Welcome);
						Boolean'Output(Buffer'Access,False);
						ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String("Rejected. Duplicated nickname."));
						LLU.Send(Client_EP, Buffer'Access);
						
						ATIO.Put_Line("Rejected. Duplicated nickname.");
					end if;
					
					if SG.Get_Number_Players(C4_Game) = SG.Get_Max_Players(C4_Game) then 
						LLU.Reset(Buffer);
						CM.Message_Type'Output(Buffer'Access, CM.Welcome);
						Boolean'Output(Buffer'Access,False);
						ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String("Could not join. Game is full."));
						LLU.Send(Client_EP, Buffer'Access);
						
						ATIO.Put_Line("Rejected. Game is full.");
					end if;
					
					if SG.Get_Number_Players(C4_Game) < SG.Get_Max_Players(C4_Game) then 
						SG.Set_Player_Info(C4_Game,Nick,Client_EP,Exists);
						
						if Exists = True then 
							LLU.Reset(Buffer);
							CM.Message_Type'Output(Buffer'Access, CM.Welcome);
							Boolean'Output(Buffer'Access,False);
							ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String("Rejected. Duplicated nickname."));
							LLU.Send(Client_EP,Buffer'Access);
						else 
							LLU.Reset(Buffer);
							CM.Message_Type'Output(Buffer'Access,CM.Welcome);
							Boolean'Output(Buffer'Access, True);
							ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String("Joined successfully."));
							LLU.Send(Client_EP,Buffer'Access);
							
							ATIO.Put_Line(ASU.To_String(Nick) & "'s game has started");
							
							LLU.Reset(Buffer);
							CM.Message_Type'Output(Buffer'Access,CM.Server);
							ASU.Unbounded_String'Output(Buffer'Access, ASU.To_Unbounded_String("There are" & Natural'Image(SG.Get_Number_Players(C4_Game)) & "/" & Natural'Image(SG.Get_Max_Players(C4_Game)))); 
							Send_All_Player_Less_One(C4_Game,Buffer'Access);
							 
							Game_Starts := True;

							
							if SG.Get_Number_Players(C4_Game) = SG.Get_Max_Players(C4_Game) then
								LLU.Reset(Buffer);
								CM.Message_Type'Output(Buffer'Access,CM.StartGame);
								ATIO.Put_Line(ASU.To_String(SG.Get_Client_Name(C4_Game,1)) & "'s' and " & ASU.To_String(SG.Get_Client_Name(C4_Game,2)) & "'s'" & "game has started");
								Send_All_Players(C4_Game,Buffer'Access);
								
								LLU.Reset(Buffer);
								CM.Message_Type'Output(Buffer'Access,CM.YourTurn);
								ASU.Unbounded_String'Output(Buffer'Access, VD.Dashboard_To_Us(SG.Get_Dashboard(C4_Game).all));
								LLU.Send(SG.Get_Client_EP(C4_Game,1), Buffer'Access);
							end if;
						end if;
					end if;
					
				when CM.Move => 
					if SG.Get_Number_Players(C4_Game) = SG.Get_Max_Players(C4_Game) then 
						
						Nick := ASU.Unbounded_String'Input(Buffer'Access);
						Column := Positive'Input(Buffer'Access);
						
						if Nick = SG.Get_Client_Name(C4_Game,SG.Get_Current_Turn(C4_Game)) then
							if Column >= 1 and Column <= 10 then 
								LLU.Reset(Buffer);
								CM.Message_Type'Output(Buffer'Access,CM.MoveReceived);
								Boolean'Output(Buffer'Access,True);
								LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), Buffer'Access); 
								
								ATIO.Put_Line(ASU.To_String(Nick) & "'s move:" & Natural'Image(Column) & " - Valid");
								
								VD.Put_Token(SG.Get_Dashboard(C4_Game).all,Column,SG.Get_Current_Turn(C4_Game),Winner);
								
								if Winner = True then 
									LLU.Reset(Buffer);
									CM.Message_type'Output(Buffer'Access,CM.EndGame);
									ASU.Unbounded_String'Output(Buffer'Access,Nick);
									ASU.Unbounded_String'Output(Buffer'Access,VD.Dashboard_To_US(SG.Get_Dashboard(C4_Game).all));
									ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String(""));
									Boolean'Output(Buffer'Access,True);
									Send_All_Players(C4_Game,Buffer'Access);
									
									ATIO.Put_Line(ASU.TO_String(Nick) & " has won the game");
	
								elsif VD.Dashboard_Is_Full(SG.Get_Dashboard(C4_Game).all) then 
									LLU.Reset(Buffer);
									CM.Message_type'Output(Buffer'Access,CM.EndGame);
									ASU.Unbounded_String'Output(Buffer'Access,ASU.To_Unbounded_String(""));
									ASU.Unbounded_String'Output(Buffer'Access,VD.Dashboard_To_US(SG.Get_Dashboard(C4_Game).all));
									ASU.Unbounded_String'Output(Buffer'Access, ASU.To_Unbounded_String(""));
									Boolean'Output(Buffer'Access,False);
									Send_All_Players(C4_Game,Buffer'Access);
									
									ATIO.Put_Line("The game has finished. Dashboard is full");
								
								else 
									SG.Next_Turn(C4_Game);
									
									LLU.Reset(Buffer);
									CM.Message_type'Output(Buffer'Access,CM.YourTurn);
									ASU.Unbounded_String'Output(Buffer'Access, VD.Dashboard_To_Us(SG.Get_Dashboard(C4_Game).all));
									LLU.Send(SG.Get_Client_EP(C4_Game, SG.Get_Current_Turn(C4_Game)), Buffer'Access); 
								
								end if;
							else
								
								Column_Error(Column, C4_Game, Nick);
							
							end if;
						end if;
					end if;
					
				when CM.Logout =>
					
					Client_EP := LLU.End_Point_Type'Input(Buffer'Access);
					Nick := ASU.Unbounded_String'Input(Buffer'Access);
					
					if Nick = SG.Get_Client_Name(C4_Game,SG.Get_Current_Turn(C4_Game)) then -- ERROR: Tienes que comprobar también el EP
						LLU.Reset(Buffer);
						CM.Message_type'Output(Buffer'Access,CM.EndGame);
						ASU.Unbounded_String'Output(Buffer'Access, ASU.To_Unbounded_String(""));
						ASU.Unbounded_String'Output(Buffer'Access, ASU.To_Unbounded_String(""));
						ASU.Unbounded_String'Output(Buffer'Access, Nick);
						Boolean'Output(Buffer'Access,False);
						Send_All_Players(C4_Game,Buffer'Access);
						
						ATIO.Put_Line(ASU.To_String(Nick) & " abandoned the game. game has finished");
						ATIO.Put_Line("Waiting for new players ...");
					
					end if;
				when others =>
					null;
			end case;
		end if;
	end loop;
	
exception
	when Usage_Error =>
		
		ATIO.Put_Line("usage " & ACL.Command_Name & " <port>");
		LLU.Finalize;
	
	when Constraint_Error =>
		
		ATIO.Put_Line("ERROR: Port must be an integer");
		LLU.Finalize;

end c4_server;
