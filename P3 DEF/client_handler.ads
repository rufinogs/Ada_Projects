with Ada.Strings.Unbounded;
with Lower_Layer_UDP;
with Ada.Exceptions;

package Client_Handler is 
	package ASU renames Ada.Strings.Unbounded;
	package LLU renames Lower_Layer_UDP;
	
	type Client_State is (
		WaitingForGame, 
		InGame ,
		OurTurn ,
		MoveRejected , 
		FinishedGame 
		);
	State: Client_State := WaitingForGame;
	
	procedure Client_Handler (From: in LLU.End_Point_Type; To: in LLU.End_Point_Type; P_Buffer: access LLU.Buffer_Type);

end Client_Handler;
