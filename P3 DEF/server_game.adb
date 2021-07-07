with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Lower_Layer_UDP;
with Vertical_Dashboard;

package body server_game is 
	package AE renames Ada.Exceptions;
	
	use type ASU.Unbounded_String;
	use type LLU.End_Point_Type;
	
	procedure Set_Player_Info(C4_Game: in out C4_Game_Type; Nick: in ASU.Unbounded_String; EP: in LLU.End_Point_Type) is
	begin
		C4_Game.Current_Players := C4_Game.Current_Players + 1;
		C4_Game.Player_Info(C4_Game.Current_Players).Nick := Nick;
		C4_Game.Player_Info(C4_Game.Current_Players).EP := EP;
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
	
	function Nick_Duplicated(C4_Game: in C4_Game_Type; Nick: in ASU.Unbounded_String) return Boolean is
	Exist: Boolean;
	I: Integer := 1;
	begin
		Exist := False;
		while not Exist and I <= C4_Game.Current_Players loop 
			if C4_Game.Player_Info(I).Nick = Nick then 
				Exist := True;
			else 
				Exist := False;
			end if;
			I := I + 1;
		end loop;
		return Exist;
	end Nick_Duplicated;
	
	function EP_Duplicated(C4_Game: in C4_Game_Type; EP: in LLU.End_Point_Type) return Boolean is --PREGUNTAR A JAVI SI ESTE PROCEDIMIENTO Y EL DE NICK DUPLICADO ESTAN BIEN
	Exist: Boolean;
	I: Integer := 1;
	begin
		Exist := False;
		while not Exist and I <= C4_Game.Current_Players loop 
			if C4_Game.Player_Info(I).EP = EP then 
				Exist := True;
			else 
				Exist := False; 
			end if;
			I := I + 1;
		end loop;
		return Exist;
	end EP_Duplicated;
		
	--function Game_To_String(C4_Game: in C4_Game_Type) return String is
		--Result: ASU.Unbounded_String;
	--begin
		--Result := ASCII.LF & ASU.To_Unbounded_String("***Players***") & ASCII.LF;
		--for I in 1..C4_Game.Current_Players loop
			--Result := Result & ASU.To_Unbounded_String("Player" & Positive'Image(I) & ";") & ASCII.LF;
			--Result := Result & ASU.To_Unbounded_String("- Nick" & ASU.To_String(C4_Game.Player_Info(I).Nick)) & ASCII.LF;
			--Result := Result & ASU.To_Unbounded_String("- EP" & LLU.Image(C4_Game.Player_Info(I).EP)) & ASCII.LF;
			--Result := Result & ASCII.LF;
		--end loop;
		
		--Result := Result & ASU.To_Unbounded_String("*** Dashboard ***") & ASCII.LF;
		--Result := Result & VD.Dashboard_To_US (C4_Game.Dashboard.all);
		
		--Result := Result & ASCII.LF;
		
		--Result := Result & ASU.To_Unbounded_String("*** Current Turn ***") & ASCII.LF;
		--Result := Result & ASU.To_Unbounded_String (Natural'Image(C4_Game.Current_Turn)); 
		
		--Result := Result & ASCII.LF;
		--Result := Result & ASU.To_Unbounded_String("*** Current Players ***") & ASCII.LF;
		--Result := Result & ASU.To_Unbounded_String (Natural'Image(C4_Game.Current_Players));
		
		--Result := Result & ASCII.LF;
		--Result := Result & ASU.To_Unbounded_String("*** Max Players ***") & ASCII.LF;
		--Result := Result & ASU.To_Unbounded_String( Natural'Image(C4_Game.Max_Players));
		
		--Result := Result & ASCII.LF;
			
		--return ASU.To_String(Result);
	--end Game_To_String;

end server_game;
