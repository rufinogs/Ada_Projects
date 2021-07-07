with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Characters.Latin_1;

package body Vertical_Dashboard is
	package ATIO renames Ada.Text_IO;
 	
 	use type ASU.Unbounded_String;
 

	function Box_Contains_Player(B: in Box; Player: in Integer) return Boolean is -- funcion que mira si la celda no esta vacia y corresponde al jugador 
	begin
		return not B.Empty and B.Player = Player;
	end Box_Contains_Player;
	
	function Has_4_Vertical(Dashboard: in Board_Type; Row: in Integer; 
		Column: in Integer; Player: in Integer) return Boolean is
		Tokens: Natural;
		Row_Aux: Integer;
		Has_4: Boolean;
	begin 
		Tokens := 0;
		Row_Aux := Dashboard'First(1);
		Has_4 := False;
		while Tokens /= 4 and Row_Aux <= Dashboard'Last(1) loop
			if Box_Contains_Player(Dashboard(Row_Aux, Column), Player) then
				Tokens := Tokens + 1;
			else
				Tokens := 0;
			end if;
			if Tokens >= 4 then 
				Has_4 := True;
			end if;
			Row_Aux := Row_Aux + 1;
		end loop;
		return Tokens = 4;
	end Has_4_Vertical;
		
	function Has_4_Horizontal(Dashboard: in Board_Type; Row: in Integer; 
		Column: in Integer; Player: in Integer) return Boolean is
		Tokens: Natural;
		Column_Aux: Integer;
		Has_4: Boolean;
	begin
		Has_4 := False;
		Tokens := 0;
		Column_Aux := Dashboard'First(2);
		while Tokens /= 4 and Column_Aux <= Dashboard'Last(2) loop
			if Box_Contains_Player(Dashboard(Row, Column_Aux), Player) then
				Tokens := Tokens + 1;
			else 
				Tokens := 0;
			end if;
			if Tokens >= 4 then 
				Has_4 := True;
			end if;
			Column_Aux := Column_Aux + 1;
		end loop;
		return Tokens = 4;
	end Has_4_Horizontal;
		
	function Has_4_Diagonal_Up_Down_LR(Dashboard: in Board_Type; Row: in Integer;  
		Column: in Integer; Player: in Integer) return Boolean is  -- LR = Left-Right, lo mira de abajo a arriba
		Tokens: Natural;
		Row_Aux: Integer;
		Column_Aux: Integer;
		Has_4: Boolean;
	begin
		Row_Aux := Row;
		Column_Aux := Column;
		Tokens := 0;
		Has_4 := False;
		while Row_Aux > Dashboard'First(1) and Column_Aux > Dashboard'First(2) loop
			Row_Aux := Row_Aux - 1;
			Column_Aux := Column_Aux - 1;
		end loop;
		
		while Tokens /= 4 and Row_Aux <= Dashboard'Last(1) and Column_Aux <= Dashboard'Last(2) loop
			if Box_Contains_Player(Dashboard(Row_Aux, Column_Aux), Player) then
				Tokens := Tokens + 1;
			else
				Tokens := 0;
			end if;
			if Tokens >= 4 then
				Has_4 := True;
			end if;
			Row_Aux := Row_Aux + 1;
			Column_Aux := Column_Aux + 1;
		end loop;
		return Tokens = 4;
	end Has_4_Diagonal_Up_Down_LR;
	
	function Has_4_Diagonal_Up_Down_RL(Dashboard: in Board_Type; Row: in Integer;
		Column: in Integer; Player: in Integer) return Boolean is  -- RL = Right-Left, lo mira de abajo a arriba
		Tokens: Natural;
		Row_Aux: Integer;
		Column_Aux: Integer;
		Has_4: Boolean;
	begin
		Row_Aux := Row;
		Column_Aux := Column;
		Tokens := 0;
		Has_4 := False;
		while Row_Aux > Dashboard'First(1) and Column_Aux < Dashboard'Last(2) loop
			Row_Aux := Row_Aux - 1;
			Column_Aux := Column_Aux + 1;
		end loop;
		
		while Tokens /= 4 and Row_Aux <= Dashboard'Last(1) and Column_Aux >= Dashboard'First(2) loop
			if Box_Contains_Player(Dashboard(Row_Aux, Column_Aux), Player) then
				Tokens := Tokens + 1;
			else
				Tokens := 0;
			end if;
			if Tokens >= 4 then 
				Has_4 := True;
			end if;
			Row_Aux := Row_Aux + 1;
			Column_Aux := Column_Aux - 1;
		end loop;
		return Tokens = 4;
	end Has_4_Diagonal_Up_Down_RL;
		
	function Has_4_Diagonal(Dashboard: in Board_Type; Row: in Integer; Column: in Integer; Player: Integer) return Boolean is
	begin
		return Has_4_Diagonal_Up_Down_LR(Dashboard,Row,Column,Player) or else Has_4_Diagonal_Up_Down_RL(Dashboard,Row,Column,Player);
	end Has_4_Diagonal;
	
	function The_Winner(Dashboard: in Board_Type; Row: in Integer; Column: in Integer; Player: in Integer) return Boolean is -- devuelve el ganador
	begin 
		return Has_4_Diagonal(Dashboard,Row,Column,Player) or else Has_4_Horizontal(Dashboard,Row,Column,Player) 
		or else Has_4_Vertical(Dashboard,Row,Column,Player);
	end The_Winner;
		
	function Column_Is_Full(Dashboard: in Board_Type; Column: in Integer) return Boolean is -- funcion que mira si la columna esta llena viendo que la primera celda esta llena
	begin
		return not Dashboard(Dashboard'First(1),Column).Empty;
	end Column_Is_Full;
	
	function Dashboard_Is_Full(Dashboard: in Board_Type) return Boolean is 
		Is_Full: Boolean;
		Column: Integer;
		Row: Integer;
	begin
		Is_Full := False;
		Row := Positive'First;
		Column := Positive'First;
		while Column <= Dashboard'Last(2) and Row = Dashboard'Last(1) loop 
			Is_Full := not Dashboard(Row,Column).Empty;
			Column := Column + 1;
		end loop;
		return Is_Full;
	end Dashboard_Is_Full;

	procedure Put_Token(Dashboard: in out Board_Type; Column: in Integer; 
		Player: in Integer; Winner: out Boolean) is
		Is_Put: Boolean;
		Row: Integer;
	begin
		if Column_Is_Full(Dashboard, Column) then
			raise Column_Full;
		else
			Is_Put := False;
			Row := Dashboard'Last(1);
			while not Is_Put and Row >= Dashboard'First(1) loop 
				if Dashboard(Row,Column).Empty then
					Dashboard(Row,Column).Player := Player;
					Dashboard(Row,Column).Empty := False;
					Is_Put := True;
				else
					Row := Row - 1;
				end if;
			end loop;
			Winner := The_Winner(Dashboard, Row, Column, Player);
		end if;
	end Put_Token;
	
	function Dashboard_To_US (Dashboard: Board_Type) return ASU.Unbounded_String is 
	Dashboard_Aux: ASU.Unbounded_String;
	begin
		for Row in 1..Dashboard'Last(1) loop
			for Column in 1..Dashboard'Last(2) loop
				if Dashboard(Row, Column).Empty then
					Dashboard_Aux := Dashboard_Aux & ASU.To_Unbounded_String(" - ");
				else
					if Dashboard(Row, Column).Player = 1 then
						Dashboard_Aux := Dashboard_Aux & ASU.To_Unbounded_String(Ada.Characters.Latin_1.ESC & "[91m" & 
							" X " & Ada.Characters.Latin_1.ESC & "[0m");
					else
						Dashboard_Aux := Dashboard_Aux & ASU.To_Unbounded_String(Ada.Characters.Latin_1.ESC & "[93m" & 
							" O " & Ada.Characters.Latin_1.ESC & "[0m");
					end if;
				end if;
			end loop;
			Dashboard_Aux := Dashboard_Aux & ASCII.LF;
		end loop;
		return Dashboard_Aux;
	end Dashboard_To_US;
	
end Vertical_Dashboard;
	
