with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Exceptions;
with ABB_Maps_G;
with server_game;

package Server_Handler is 
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	package SG renames server_game;
	
	package ABB_Maps is new ABB_Maps_G(Key_Type => ASU.Unbounded_String, 
		Value_Type => SG.C4_Game_Type, 
		"=" => ASU."=", 
		"<" => ASU."<", 
		">" => ASU.">", 
		Key_To_String => ASU.To_String);
--		Value_To_String => SG.Game_To_String);
	
	Map: ABB_Maps.Map; 
	
	procedure Server_Handler(From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type);
	
end Server_Handler;
