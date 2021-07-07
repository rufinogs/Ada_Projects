
with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Vertical_Dashboard;

package Server_Game is
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	package VD renames Vertical_Dashboard;
	
	Player_Exists_Error, Player_Out_Of_Range: Exception;
	
	type Client_Type is record 
		Nick: ASU.Unbounded_String;
		EP: LLU.End_Point_Type;
	end record;
	
	type Array_Client_Type is array (1..2) of Client_Type;
	
	type C4_Game_Type is private;
	
	procedure Set_Player_Info(C4_Game: in out C4_Game_Type; 
						Nick: in ASU.Unbounded_String; 
						EP: in LLU.End_Point_Type);
							  
	function Get_Dashboard(C4_Game: in C4_Game_Type) 
				return access VD.Board_Type;
		
	function Get_Client_EP(C4_Game: in C4_Game_Type; 
				Client: Integer) 
				return LLU.End_Point_Type;
	
	function Get_Client_Name(C4_Game: in C4_Game_Type; 
				Client: Integer) 
				return ASU.Unbounded_String;
	
	function Get_Number_Players (C4_Game: in C4_Game_Type) 
				return Natural;
	
	function Get_Max_Players (C4_Game: in C4_Game_Type) 
				return Natural;
	
	function Get_Current_Turn (C4_Game: in C4_Game_Type) 
				return Natural;
	
	procedure Next_Turn(C4_Game: in out C4_Game_Type);
	
	function Nick_Duplicated(C4_Game: in C4_Game_Type; Nick: in ASU.Unbounded_String) return Boolean;
	
	function EP_Duplicated(C4_Game: in C4_Game_Type; EP: in LLU.End_Point_Type) return Boolean;

	--function Game_To_String(C4_Game: in C4_Game_Type) return String;
	
	private

		type C4_Game_Type is record
			Player_Info: Array_Client_Type;
			Dashboard: access VD.Board_Type := 
						new VD.Board_Type;
			Current_Turn: Natural := 1;
			Current_Players: Natural := 0;
			Max_Players: Natural := VD.Max_Players;
		end record;
end Server_Game;

