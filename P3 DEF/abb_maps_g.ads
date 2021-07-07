generic
	type Key_Type is private;
	type Value_Type is private;
	with function "=" (K1, K2: Key_Type) return Boolean;
	with function "<" (K1, K2: Key_Type) return Boolean;
	with function ">" (K1, K2: Key_Type) return Boolean;
	with function Key_To_String (K: Key_Type) return String;
package ABB_Maps_G is
	type Map is limited private;
	
	procedure Get(M: Map; 
		Key: in Key_Type; Value: out Value_Type; 
		Success: out Boolean);

	procedure Put(M: in out Map; 
		Key: in Key_Type; 
		Value: in Value_Type);

	procedure Delete(M: in out Map; 
		Key: in Key_Type; 
		Success: out Boolean);

	function Map_Length(M: in Map) return Natural;
	
	function Is_Empty(M: in Map) return Boolean;
	function Get_Key(M: in Map) return Key_Type;
	function Get_Value(M: in Map) return Value_Type;
	function Get_Left(M: in Map) return Map;
	function Get_Right(M: in Map) return Map;
private
	type Tree_Node;
	type Map is access Tree_Node;
	type Tree_Node is record
		Key: Key_Type;
		Value: Value_Type;
		Left: Map;
		Right: Map;
	end record;
end ABB_Maps_G;
