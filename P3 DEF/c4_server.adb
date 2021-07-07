with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Server_Handler;
with server_game;

with abb_maps_g;

procedure c4_server is 
	package ATIO renames Ada.Text_IO;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package ASU renames Ada.Strings.Unbounded;
	package AE renames Ada.Exceptions;
	package SH renames Server_Handler;
	package SG renames server_game;
	
	use type ASU.Unbounded_String;
	
	Usage_Error: exception;
	
	N_Args : constant Integer := 1;
	
	Port: Integer;
	Server_EP: LLU.End_Point_Type;
	C: Character;
	Game_Ends: Boolean;

begin
	if ACL.Argument_Count /= N_Args then
		raise Usage_Error;
	end if;
		
	Port := Integer'Value(ACL.Argument(1));

	Server_EP := LLU.Build(LLU.To_IP(LLU.Get_Host_Name), Port);
	LLU.Bind(Server_EP, SH.Server_Handler'Access);

	ATIO.Put_Line("Listening on port" & Integer'Image(Port) & ":");
	ATIO.Put_Line("To close this server put 'N' or 'n'");
	
	Game_Ends := False;
	
	
	loop
		ATIO.Get_Immediate(C);
		if C = 'n' or C = 'N' then 
			ATIO.New_Line;
			ATIO.Put_Line("======== NUMBER OF GAMES ==========");
			ATIO.Put_Line("Server is currently hosting: " & Natural'Image(SH.ABB_Maps.Map_Length(SH.Map)) & " games"); 
			ATIO.Put_Line("-----------------------------------");
		end if;
	end loop;

exception
	when Usage_Error =>
		
		ATIO.Put_Line("usage " & ACL.Command_Name & " <port>");
		LLU.Finalize;
	
	when Constraint_Error =>
		
		ATIO.Put_Line("ERROR: Port must be an integer");
		LLU.Finalize;
	
end c4_server;















