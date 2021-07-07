with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Lower_Layer_UDP;
with Vertical_Dashboard;

package body server_game is 
	package AE renames Ada.Exceptions;
	
	use type ASU.Unbounded_String;
	
	procedure Set_Player_Info(C4_Game: in out C4_Game_Type; Nick: in ASU.Unbounded_String; EP: in LLU.End_Point_Type; Exists: out Boolean) is
		I: Integer := 1;
	begin
		Exists := False;
		while not Exists and I <= C4_Game.Max_Players loop
			if C4_Game.Player_Info(I).Nick = Nick then 
				Exists := True;
			end if;
			I := I + 1;
		end loop;
		
		if not Exists then
			C4_Game.Current_Players := C4_Game.Current_Players + 1;
			C4_Game.Player_Info(C4_Game.Current_Players).Nick := Nick;
			C4_Game.Player_Info(C4_Game.Current_Players).EP := EP;
		end if;
	end Set_Player_Info;
							  
	function Get_Dashboard(C4_Game: in C4_Game_Type) return access VD.Board_Type is
	begin
		return C4_Game.Dashboard;
	end Get_Dashboard;

	function Get_Client_EP(C4_Game: in C4_Game_Type; Client: Integer) return LLU.End_Point_Type is
	begin
		if Client < 1 or Client > C4_Game.Max_Players then
			raise Player_Out_Of_Range;
		else
			return C4_Game.Player_Info(Client).EP;
		end if;
	end Get_Client_EP;
	
	function Get_Client_Name(C4_Game: in C4_Game_Type; Client: Integer) return ASU.Unbounded_String is
	begin
		if Client < 1 or Client > C4_Game.Max_Players then 
			raise Player_Out_Of_Range;
		else
			return C4_Game.Player_Info(Client).Nick;
		end if;
	end Get_Client_Name;
	
	function Get_Number_Players (C4_Game: in C4_Game_Type) return Natural is
	begin 
		return C4_Game.Current_Players;
	end Get_Number_Players;
	
	function Get_Max_Players (C4_Game: in C4_Game_Type) return Natural is 
	begin
		return C4_Game.Max_Players;
	end Get_Max_Players;
	
	function Get_Current_Turn (C4_Game: in C4_Game_Type) return Natural is
	begin 
		return C4_Game.Current_Turn;
	end Get_Current_Turn;	
	
	procedure Next_Turn (C4_Game: in out C4_Game_Type) is
	begin
		if C4_Game.Current_Turn /= C4_Game.Max_Players then
			C4_Game.Current_Turn := C4_Game.Current_Turn + 1;
		else 
			C4_Game.Current_Turn := 1;
		end if;
	end Next_Turn;
end server_game;

