with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Vertical_Dashboard;
with Moves;

procedure Conecta4 is
	package ACL renames Ada.Command_Line;
	package ATIO renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	package AE renames Ada.Exceptions;
	package VD renames Vertical_Dashboard;
	
	Usage_Error: exception;
	Column_Error: exception;
	
	NMin_Args: constant Natural := 0;
	NMax_Args: constant Natural := 2;
	NMin_Columns: constant Positive := 9;
	NMax_Columns: constant Positive := 18;	
	
	N_Columns: Integer;
	Movements: Moves.Move_List_Type;
	N_Movements: Integer;
	Finish: Boolean;
	Player: VD.Player_Range;
	Response: ASU.Unbounded_String;
	Column: Integer;
	Winner: Boolean;
	Option: Integer;
begin
	-- Control de argumentos
	
	if ACL.Argument_Count /= NMin_Args and ACL.Argument_Count /= NMax_Args then
		raise Usage_Error;
	end if;
	
	if ACL.Argument_Count = NMax_Args then
		if ACL.Argument(1) = "-c" then
			N_Columns := Integer'Value(ACL.Argument(2));
			if N_Columns < NMin_Columns or N_Columns > NMax_Columns then
				raise Column_Error;
			end if;
		else
			raise Usage_Error;
		end if;
	else
		N_Columns := NMin_Columns;
	end if;
	
	--
	
	declare
		Dashboard: VD.Board_Type(1..N_Columns, 1..N_Columns);
		
		procedure Menu_Dashboard(Option: out Integer) is --procedimiento para elegr la opcion del menu
		begin
			ATIO.Put_Line("Options");
			ATIO.Put_Line("1.- Show movements");
			ATIO.Put_Line("2.- Show last n movements");
			ATIO.Put_Line("3.- Continue");
			ATIO.Put_Line("4.- Exit");
			ATIO.New_Line;
			ATIO.Put("Option >> ");
			Option:= Integer'Value(ATIO.Get_Line);
		end Menu_Dashboard;
		
	begin
		
		ATIO.Put_Line("You are going to start a game for 2 Players on a" & 
			Integer'Image(Dashboard'Length(1)) & " x" & Integer'Image(Dashboard'Length(2)) & " board");
		
		Player := VD.Player_Range'First;
		Finish := False;
		loop
			ATIO.Put("Player" & VD.Player_Range'Image(Player) & ": Enter the column where to drop the token: ");
			Response := ASU.To_Unbounded_String(ATIO.Get_Line);
			if ASU.To_String(Response) = "menu" then
				Menu_Dashboard(Option);
				if Option = 1 then
					Moves.Print_All(Movements);
				elsif Option= 2 then
					ATIO.Put("How many moves do you want to show? >> ");
					N_Movements := Integer'Value(ATIO.Get_Line);
					Moves.Print_Last_N_Moves(Movements, N_Movements);
				elsif Option = 3 then
					null;
				elsif Option = 4 then
					ATIO.Put_Line("You finish the game! I hope you have been enjoyed. Bye!");
					Finish := True;
				else
					ATIO.Put_Line("Invalid option");
				end if;
				ATIO.New_Line;
			else
				begin
					Column := Integer'Value(ASU.To_String(Response));
					VD.Put_Token(Dashboard, Column, Player, Winner);
					Moves.Add_Move(Movements, Player, Column);
					if Winner then
						Finish := True;
						ATIO.Put_Line("Player" & VD.Player_Range'Image(Player) & 
							" has won in" & Natural'Image(Moves.Count_Turns(Movements)) & " turns!");
						VD.Print_Dashboard(Dashboard);
						ATIO.New_Line;
						ATIO.Put("Do you want to save the moves? (y/n) >> ");
						Response := ASU.To_Unbounded_String(ATIO.Get_Line);
						if ASU.To_String(Response) = "y" or ASU.To_String(Response) = "Y" then
							ATIO.Put("Where do you want to save them? >> ");
							Response := ASU.To_Unbounded_String(ATIO.Get_Line);
							Moves.Save_In_File(Movements, ASU.To_String(Response));
							ATIO.Put("Moves have been saved!");
						end if;
					else
						VD.Print_Dashboard(Dashboard);
						Player := Player mod 2 + 1;
						
						if VD.Dashboard_Is_Full(Dashboard) then
							ATIO.Put_Line("Tie!");
							Finish := True;			
						end if;
					end if;
				exception
					when VD.Column_Full =>
						ATIO.Put_Line("The chosen column is full. No more tokens can be added to it");
					when Constraint_Error =>
						ATIO.Put_Line("Please, enter a valid column (Between " & 
							Positive'Image(Dashboard'First(2)) & " y" & Positive'Image(Dashboard'Last(2)) & ")" );
				end;
			end if;
		exit when Finish;
		end loop;
		
		Moves.Delete_List(Movements);
	end;
exception
	when Usage_Error =>
		ATIO.Put_Line("Please put conecta4 -c [The number of Columns]");
	when Column_Error =>
		ATIO.Put_Line("Column_Error: The minimum number of columns is" & Positive'Image(NMin_Columns) & " and the maximum is" & Positive'Image(NMax_Columns) & ".");
	when Ex:others =>
		ATIO.Put_Line("unexpected exception: " & AE.Exception_Name(Ex) & " in " & AE.Exception_Message(Ex));
end Conecta4;
