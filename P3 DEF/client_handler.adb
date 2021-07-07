with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with c4_messages;
with Ada.Text_IO;
with vertical_dashboard;

package body client_handler is 
	package CM renames c4_messages;
	package ATIO renames Ada.Text_IO;
	package VD renames vertical_dashboard;
	use type CM.Message_Type;
	
	procedure Write_EndGame(Winner: in ASU.Unbounded_String; Quitter: in ASU.Unbounded_String) is
	begin
		if ASU.Length(Winner) /= 0 then 
			ATIO.New_Line;
			ATIO.Put_Line("The winner is " & ASU.To_String(Winner) & "."); 
		elsif ASU.Length(Quitter) /= 0 then 
			ATIO.New_Line;
			ATIO.Put_Line(ASU.To_String(Quitter) & " has left the game.");
		else 
			ATIO.Put_Line("Nobody wins. The Dashboard is full.");
		end if; 
	end Write_EndGame;
	
	procedure Client_Handler (From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type) is
	Message: ASU.Unbounded_String; 
	Response: CM.Message_Type;
	Accepted: Boolean;
	Winner: ASU.Unbounded_String;
	Quitter: ASU.Unbounded_String;
	Dashboard: ASU.Unbounded_String;
	YouWin: Boolean;
	begin
		Response := CM.Message_type'Input(P_Buffer);		
		case Response is 
			when CM.StartGame =>
				State := InGame;
				ATIO.Put_Line("The Game Starts!"); 
				
			when CM.Server =>
				Message := ASU.Unbounded_String'Input(P_Buffer);
				ATIO.Put_Line(ASU.To_String(Message));
			
			when CM.YourTurn =>
				State := OurTurn;
				ATIO.Put_Line("Is your turn..."); 
				
			when CM.MoveReceived =>
				Accepted := Boolean'Input(P_Buffer);
				if Accepted = True then 
					State := InGame;
					ATIO.Put_Line("Waiting for the next player"); 
				else 
					State := MoveRejected;
					ATIO.Put_Line("Rejected move"); 
				end if;
			when CM.EndGame =>
				Winner := ASU.Unbounded_String'Input(P_Buffer);
				Dashboard := ASU.Unbounded_String'Input(P_Buffer);
				Quitter := ASU.Unbounded_String'Input(P_Buffer);
				YouWin := Boolean'Input(P_Buffer);
				
				Write_EndGame(Winner,Quitter);
				
				State := FinishedGame;
			when others =>
				null;
		end case;
	end Client_Handler;
	
end client_handler;
