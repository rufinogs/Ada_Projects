with Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Ada.IO_Exceptions;
with Ada.Exceptions;


package body Moves is
	package ATIO renames Ada.Text_IO;
	package AIOE renames Ada.IO_Exceptions;
	package AE renames Ada.Exceptions;

	procedure Add_Move (List: in out Move_List_Type; 
		      Player: in Natural; Column: in Natural) is
		      P_New: Move_List_Type;
		      P_Aux: Move_List_Type;
	begin
		P_New := new Cell'(Player,Column,null);
		if List = null then 
			List := P_New;
		else
			P_Aux := List;
			while P_Aux.Next /= null loop
				P_Aux := P_Aux.Next;
			end loop;
				P_Aux.Next := P_New;
		end if;
	end Add_Move;
	
	procedure Print_All(List: in Move_List_Type) is 
		P_Aux: Move_List_Type;
	begin
		P_Aux := List;
		while P_Aux /= null loop
			ATIO.Put_Line("| Player " & Natural'Image(P_Aux.Player) & 
				" | - Column " & Natural'Image(P_Aux.Column));
				
			P_Aux := P_Aux.Next;
		end loop;
	end Print_All;
	
	function Total_Moves (List: in Move_List_Type) return Natural is -- funcion que devuelve todos los movimientos 
		Total : Natural;
		P_Aux : Move_List_Type;
	begin
		Total := 0;
		P_Aux := List;
		while P_Aux /= null loop
			Total := Total + 1;
			P_Aux := P_Aux.Next;
		end loop;
		return Total;
	end Total_Moves;

	procedure Print_Last_N_Moves(List: in Move_List_Type; N: in Integer) is 
		P_Aux : Move_List_Type;
		N_Moves : Integer;
		N_First_Moves : Integer;
		Counter : Integer;
	begin
		N_Moves := Total_Moves(List);
		if N_Moves = 0 then
			ATIO.Put_Line("There are not any movements to show");
		else
			N_First_Moves := N_Moves - N; -- Celdas (movimientos) que te tienes que saltar
		
			Counter := 1; -- Posición de la primera celda
			P_Aux := List;
			while P_Aux /= null loop
				if Counter > N_First_Moves then 
					ATIO.Put_Line("| Player" & Natural'Image(P_Aux.Player) & 
						" | - Column" & Natural'Image(P_Aux.Column)); -- Aquí se imprime el movimiento
				end if;
				Counter := Counter + 1;
				P_Aux := P_Aux.Next;
			end loop;
		end if;
	end Print_Last_N_Moves;
	 
	procedure Save_In_File(List: in Move_List_Type; File_Name: String) is
		File: ATIO.File_Type;
		P_Aux: Move_List_Type;
	begin
		ATIO.Create(File, ATIO.Out_File, File_Name);
		
		P_Aux := List;
		while P_Aux /= null loop
			ATIO.Put_Line(File, "| Player" & Natural'Image(P_Aux.Player) & 
				" | - Column" & Natural'Image(P_Aux.Column));
			
			P_Aux := P_Aux.Next;
		end loop;
		
		ATIO.Close(File);
		exception
			when AIOE.Name_Error =>
				ATIO.Put_Line("It wasn't possible to create the file with the name " & File_Name);
		
	end Save_In_File;

	function Count_Turns(List: in Move_List_Type) return Natural is --función que cuenta los turnos de los jugadores
		Turns: Natural;
	begin
		Turns := Total_Moves(List);
		if Turns mod 2 = 0 then 
			return Turns / 2;
		else 
			return (Turns / 2) + 1;
		end if;
	end Count_Turns;
	
	procedure Remove is new Ada.Unchecked_Deallocation(Cell, Move_List_Type); -- procedimiento que permite borrar las celdas
		      
	procedure Delete_List(List: in out Move_List_Type) is 
		P_Aux: Move_List_Type;
	begin
		while P_Aux /= null loop
			P_Aux := List;
			List := List.Next;
			Remove(P_Aux);
		end loop;
	end Delete_List;
end Moves;
