with Ada.Command_Line;
with C4_Messages;
with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Client_Handler;
with Ada.Exceptions;

procedure c4_client is 
	package ACL renames Ada.Command_Line;
	package CM renames c4_messages;
	package LLU renames Lower_Layer_UDP;
	package ATIO renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	package CH renames Client_Handler;
	use type CH.Client_State; 
	
	Usage_error: exception;
	N_Args1: constant Integer := 3;
	N_Args2: constant Integer := 4;
	
	procedure Send_Join(Client_EP_Receive: in LLU.End_Point_Type; Client_EP_Handler: LLU.End_Point_Type; Nick: in ASU.Unbounded_String; Game_Key: in ASU.Unbounded_String; Server_EP: in LLU.End_Point_Type) is
	Buffer: aliased LLU.Buffer_Type(2048);
	begin
		LLU.Reset(Buffer);
		CM.Message_type'Output(Buffer'Access,CM.Join);
		LLU.End_Point_Type'Output(Buffer'Access,Client_EP_Receive);
		LLU.End_Point_Type'Output(Buffer'Access,Client_EP_Handler);
		ASU.Unbounded_String'Output(Buffer'Access,Nick);
		ASU.Unbounded_String'Output(Buffer'Access,Game_Key);
		LLU.Send(Server_EP, Buffer'Access);
	end;
	
	procedure Send_Logout(Game_Key: in ASU.Unbounded_String; Nick: in ASU.Unbounded_String; Client_EP_Handler:in LLU.End_Point_Type; Server_EP: in LLU.End_Point_Type) is
	Buffer: aliased LLU.Buffer_Type(2048);
	begin
		LLU.Reset(Buffer);
		CM.Message_type'Output(Buffer'Access, CM.Logout);
		ASU.Unbounded_String'Output(Buffer'Access,Game_Key);
		ASU.Unbounded_String'Output(Buffer'Access,Nick);
		LLU.End_Point_Type'Output(Buffer'Access,Client_EP_Handler);
		LLU.Send(Server_EP,Buffer'Access);
	end;
	
	procedure Send_Move(Column: in Positive; Game_Key: in ASU.Unbounded_String; Server_EP: in LLU.End_Point_Type) is
	Buffer: aliased LLU.Buffer_Type(2048);
	begin
		CM.Message_type'Output(Buffer'Access,CM.Move);
		Positive'Output(Buffer'Access, Column);
		ASU.Unbounded_String'Output(Buffer'Access,Game_Key);
		LLU.Send(Server_EP,Buffer'Access);
	end;

	Host: ASU.Unbounded_String;
	Port: Integer;
	Nick: ASU.Unbounded_String;
	Game_Key: ASU.Unbounded_String;
	Server_EP: LLU.End_Point_Type;	
	Client_EP_Handler: LLU.End_Point_Type;
	Client_EP_Receive: LLU.End_Point_Type;
	Buffer: aliased LLU.Buffer_Type(2048);
	Accepted: Boolean;
	Header: CM.Message_type;
	Reason: ASU.Unbounded_String;
	Game_Ends: Boolean;
	C: Character;
	Available: Boolean;
	Move_Is_Valid: Boolean;
	The_Word: ASU.Unbounded_String;
	Column: Positive;
	Expired: Boolean;
	
	use type ASU.Unbounded_String;
	
begin 
	if ACL.Argument_Count /= N_Args1 and ACL.Argument_Count /= N_Args2 then
		raise Usage_error;
	end if;
	
	Host := ASU.To_Unbounded_String(ACL.Argument(1));
	Port := Integer'Value(ACL.Argument(2));
	Nick := ASU.To_Unbounded_String(ACL.Argument(3));
	if ACL.Argument_Count = N_Args2 then
		Game_Key := ASU.To_Unbounded_String(ACL.Argument(4));
	end if;
	
	Server_EP := LLU.Build(LLU.To_IP(ASU.To_String(Host)), Port);
	LLU.Bind_Any(Client_EP_Receive);
	LLU.Bind_Any(Client_EP_Handler, CH.Client_Handler'Access); 
	
	Send_Join(Client_EP_Receive,Client_EP_Handler,Nick,Game_Key,Server_EP);

	LLU.Reset(Buffer);
	LLU.Receive(Client_EP_Receive, Buffer'Access, 10.0, Expired);
	if not Expired then 
		Header := CM.Message_type'Input(Buffer'Access);
		Accepted := Boolean'Input(Buffer'Access);
		Reason := ASU.Unbounded_String'Input(Buffer'Access);
		Game_Key := ASU.Unbounded_String'Input(Buffer'Access);
		
		if Accepted = True then 
			ATIO.Put_Line("C4 Game Client: Welcome " & ASU.To_String(Nick));
			ATIO.Put_Line("Waiting for game to start...");

			Game_Ends := False;
			loop
				case CH.State is
					when CH.WaitingForGame | CH.InGame =>
						ATIO.Get_Immediate(C, Available);
						if Available = True then 
							if C = 'Q' or C = 'q' then 
								ATIO.New_Line;
								ATIO.Put_Line("Are you sure you want to quit? (Y/N)");
								The_Word := ASU.To_Unbounded_String(ATIO.Get_Line);
								
								if ASU.To_String(The_Word) = "Y" or ASU.To_String(The_Word) = "y" then 
									Send_Logout(Game_Key,Nick,Client_EP_Handler,Server_EP);
									ATIO.New_Line;
									ATIO.Put_Line("You have abandoned the game");
									CH.State := CH.FinishedGame;
									Game_Ends := True;
								else
									null;
								end if;
							end if;
						end if;
					when CH.OurTurn | CH.MoveRejected => 
						Move_Is_Valid := False;
						loop	
							begin
								ATIO.Put("This is your turn, enter your move: ");
								Column := Positive'Value(ATIO.Get_Line);
								Move_Is_Valid := True;
								LLU.Reset(Buffer);
								Send_Move(Column,Game_Key,Server_EP);
								if CH.State /= CH.FinishedGame then 
									CH.State := CH.InGame; 
								end if;
							exception
								when Constraint_Error =>
									ATIO.Put_Line("Error. Yo can only write a number");
							end;
						exit when Move_Is_Valid;
						end loop;
						
					when CH.FinishedGame =>
						Game_Ends := True;
				end case;
			exit when Game_Ends; 
			end loop;
		end if;
	else 
		ATIO.Put_Line("Server Unreachable");
	end if;
	
	LLU.Finalize;
	
exception
	when Usage_Error =>
		ATIO.Put_Line("usage: " & ACL.Command_Name & " <host> <port> <nick> <game key>");
		LLU.Finalize;
	when Constraint_Error =>
		ATIO.Put_Line("ERROR: Port must be an integer");
		LLU.Finalize;
		
end c4_client;












