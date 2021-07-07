with Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body ABB_Maps_G is
	package ATIO renames Ada.Text_IO;

	procedure Get(M: Map; 
		Key: in Key_Type; 
		Value: out Value_Type; 
		Success: out Boolean) is
	begin
		if M = null then
			Success := False;
		elsif Key = M.Key then
			Value := M.Value;
			Success := True;
		elsif Key > M.Key then
			Get(M.Right, Key, Value, Success);
		else
			Get(M.Left, Key, Value, Success);
		end if;
	end Get;

	procedure Put(M: in out Map; 
		Key: in Key_Type; 
		Value: in Value_Type) is
	begin
		if M = null then
			M := new Tree_Node'(Key, Value, null, null);
		elsif Key = M.Key then
			M.Value := Value;
		elsif Key > M.Key then
			Put(M.Right, Key, Value);
		else
			Put(M.Left, Key, Value);
		end if;
	end Put;

	procedure Min(M: in Map; 
		Key: out Key_Type; 
		Value: out Value_Type; 
		Success: out Boolean) is
	begin
		if M = null then
			Success := False;
		else
			if M.Left = null then
				Success := True;
				Key := M.Key;
				Value := M.Value;
			else
				Min(M.Left, Key, Value, Success);
			end if;
		end if;
	end Min;

	procedure Free is new Ada.Unchecked_Deallocation(Tree_Node, Map);
	
	procedure Delete(M: in out Map; 
		Key: in Key_Type; 
		Success: out Boolean) is
		P_Aux: Map;
		Min_Key: Key_Type;
		Min_Value: Value_Type;
		Min_Success: Boolean;
	begin
		if M = null then
			Success := False;
		elsif Key = M.Key then
			Success := True;
			if M.Left = null then
				P_Aux := M.Right;
				Free(M);
				M := P_Aux;
			elsif M.Right = null then
				P_Aux := M.Left;
				Free(M);
				M := P_Aux;
			else
				Min(M.Right, Min_Key, Min_Value, Min_Success);
				if Min_Success then
					M.Key := Min_Key;
					M.Value := Min_Value;
					Delete(M.Right, Min_Key, Success);
				end if;
			end if;
		elsif Key > M.Key then
			Delete(M.Right, Key, Success);
		else
			Delete(M.Left, Key, Success);
		end if;
	end Delete;

	function Map_Length(M: in Map) return Natural is
	begin
		if M = null then
			return 0;
		else
			return 1 + Map_Length(M.Left) + Map_Length(M.Right);
		end if;
	end Map_Length;

	function Is_Empty(M: in Map) return Boolean is
	begin
		return M = null;
	end Is_Empty;
	
	function Get_Key(M: in Map) return Key_Type is
	begin
		return M.Key;
	end Get_Key;
	
	function Get_Value(M: in Map) return Value_Type is
	begin
		return M.Value;
	end Get_Value;
	
	function Get_Left(M: in Map) return Map is
	begin
		return M.Left;
	end Get_Left;
	
	function Get_Right(M: in Map) return Map is
	begin
		return M.Right;
	end Get_Right;
end ABB_Maps_G;











