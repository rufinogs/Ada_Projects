with Ada.Strings.Unbounded;

package Moves is
	package ASU renames Ada.Strings.Unbounded;
	
	type Cell;
	
	type Move_List_Type is access Cell;
	
	type Cell is record
		Player: Natural;
		Column: Natural;
		Next: Move_List_Type;
	end record;
	
	procedure Add_Move (List: in out Move_List_Type; 
		      Player: in Natural; Column: in Natural);
		      
	procedure Print_All(List: in Move_List_Type);
	
	procedure Print_Last_N_Moves(List: in Move_List_Type; N:in Integer);
	
	procedure Save_In_File(List: in Move_List_Type; File_Name: String);
	
	function Count_Turns(List: in Move_List_Type) return Natural;
	
	procedure Delete_List(List: in out Move_List_Type);
	
end Moves;







