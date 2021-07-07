with Ada.Command_Line;
with C4_Messages;
with Lower_Layer_UDP;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

procedure c4_client is 
	package ACL renames Ada.Command_Line;
	package CM renames c4_messages;
	package LLU renames Lower_Layer_UDP;
	package ATIO renames Ada.Text_IO;
	package ASU renames Ada.Strings.Unbounded;
	
	Usage_error: exception;
	N_Args: constant Integer := 3;
	
	use type ASU.Unbounded_String;
	
	Port: Integer;
	Host: ASU.Unbounded_String;
	Client_EP: LLU.End_Point_Type;
	Server_EP:LLU.End_Point_Type;
	Nick: ASU.Unbounded_String;
	Buffer: aliased LLU.Buffer_Type(2048);
	Expired: Boolean;
	Header: CM.Message_type;
	Reason: ASU.Unbounded_String;
	Accepted: Boolean;
	Message: ASU.Unbounded_String;
	Game_Start: Boolean;
	Game_Ends: Boolean;
	Response: CM.Message_type;
	Column: Positive;
	The_Word: ASU.Unbounded_String;
	The_Word2: ASU.Unbounded_String;
	Dashboard: ASU.Unbounded_String;
	Move_Is_Valid: Boolean;
	Winner: ASU.Unbounded_String;
	Quitter: ASU.Unbounded_String;
	Nick_wins: ASU.Unbounded_String;
	Youwin: Boolean;
	
begin 
	if ACL.Argument_Count /= N_Args then
		raise Usage_error;
	end if;
	
	Host := ASU.To_Unbounded_String(ACL.Argument(1));
	Port := Integer'Value(ACL.Argument(2));
	Nick := ASU.To_Unbounded_String(ACL.Argument(3));
	
	Server_EP := LLU.Build(LLU.To_IP(ASU.To_String(Host)), Port);
	LLU.Bind_Any(Client_EP);
	
	CM.Message_type'Output(Buffer'Access,CM.Join);
	LLU.End_Point_Type'Output(Buffer'Access,Client_EP);
	ASU.Unbounded_String'Output(Buffer'Access,Nick);
	LLU.Send(Server_EP, Buffer'Access);

	LLU.Reset(Buffer);
	LLU.Receive(Client_EP, Buffer'Access, 10.0, Expired);
	if not Expired then 
		Header := CM.Message_type'Input(Buffer'Access);
		Accepted := Boolean'Input(Buffer'Access);
		Reason := ASU.Unbounded_String'Input(Buffer'Access);
		if Accepted = True then 
			ATIO.Put_Line("C4 Game Client: Welcome " & ASU.To_String(Nick));
			ATIO.Put_Line("Waiting for game to start...");

			Game_Start := False;
			loop
				LLU.Reset(Buffer);
				LLU.Receive(Client_EP, Buffer'Access, 10.0, Expired);
				if not Expired then
					Response := CM.Message_type'Input(Buffer'Access);
					case Response is
						when CM.StartGame =>
							Game_Start := True;
							ATIO.Put_Line("     -- Game Started --");
						when others => -- Server
							Message := ASU.Unbounded_String'Input(Buffer'Access);
							ATIO.Put_Line(ASU.To_String(Message));
					end case;
				end if;
			exit when Game_Start;
			end loop;
			
			Game_Ends := False;
			loop
				LLU.Reset(Buffer);
				LLU.Receive(Client_EP, Buffer'Access, 10.0, Expired);
				if not Expired then
					Response := CM.Message_type'Input(Buffer'Access);
					case Response is
						when CM.YourTurn =>
							Dashboard := ASU.Unbounded_String'Input(Buffer'Access);
							ATIO.Put_Line(ASU.To_String(Dashboard));
							Move_Is_Valid := False;
							loop
								ATIO.Put_Line("This is your turn, enter your move: ");
								The_Word := ASU.To_Unbounded_String(ATIO.Get_Line);
								
								if ASU.To_String(The_Word) = "quit" or ASU.To_String(The_Word) = "Quit" then 
									ATIO.New_Line;
									ATIO.Put_Line("Are you sure you want to quit? (Y/N)");
									The_Word2 := ASU.To_Unbounded_String(ATIO.Get_Line);
									
									if ASU.To_String(The_Word2) = "Y" or ASU.To_String(The_Word2) = "y" then 
										LLU.Reset(Buffer);
										CM.Message_type'Output(Buffer'Access, CM.Logout);
										LLU.End_Point_Type'Output(Buffer'Access,Client_EP);
										ASU.Unbounded_String'Output(Buffer'Access,Nick);
										LLU.Send(Server_EP,Buffer'Access);
										ATIO.New_Line;
										ATIO.Put_Line("You have abandoned the game");
										Game_Ends := True;
										Move_Is_Valid := True; 
									end if;
								else
									begin
										Column := Positive'Value(ASU.To_String(The_Word));
										LLU.Reset(Buffer);
										CM.Message_type'Output(Buffer'Access,CM.Move);
										ASU.Unbounded_String'Output(Buffer'Access, Nick);
										Positive'Output(Buffer'Access, Column);
										LLU.Send(Server_EP,Buffer'Access);
										loop
											LLU.Reset(Buffer);
											LLU.Receive(Client_EP, Buffer'Access, 10.0, Expired);
											if not Expired then
												Response := CM.Message_type'Input(Buffer'Access);
												Accepted := Boolean'Input(Buffer'Access);
												if Accepted then
													Move_Is_Valid := True;
												else
													ATIO.Put_Line("Move rejected. Enter a value between 1 and 10:");
													ATIO.New_Line;
													Column := Positive'Value(ASU.To_String(The_Word));
													Move_Is_Valid := False;
												end if;
											end if;
										exit when not Expired;
										end loop;
									exception
										when Constraint_Error =>
											ATIO.Put_Line("ERROR: Invalid Move");
											ATIO.New_Line;
											ATIO.Put_Line("IMPORTANT: Value rejected. Put a Number between 1 and 10, words or characters aren't' correct except quit");
											ATIO.New_Line;
											Move_Is_Valid := False;
									end;
								end if;
							exit when Move_Is_Valid;
							end loop;
						when CM.EndGame => 
						Nick_wins := ASU.Unbounded_String'Input(Buffer'Access);
						Dashboard := ASU.Unbounded_String'Input(Buffer'Access);
						Quitter := ASU.Unbounded_String'Input(Buffer'Access);
						Youwin := Boolean'Input(Buffer'Access);
						Game_Ends := False;
							if Youwin = True then 
								if Nick = Nick_wins then
									ATIO.Put_Line(ASU.To_String(Dashboard));
									ATIO.Put_Line("You have won the game!");
								end if;
								if Quitter /= Nick then
									ATIO.New_Line;
									ATIO.Put_Line(ASU.To_String(Nick_wins) & " has won the game!");
									Game_Ends := True;
								end if;
							else 
								ATIO.New_Line;
								ATIO.Put_Line("Nobody wins!");
								Game_Ends := True;
							end if;	
						when others =>
							null;
					end case;
				end if;
			exit when Game_Ends;
			end loop;
		else
			ATIO.Put_Line(ASU.To_String(Reason));
		end if;
	else 
		ATIO.Put_Line("Server Unreachable.");
	end if;
	
	LLU.Finalize;
	
exception
	when Usage_Error =>
		ATIO.Put_Line("usage: " & ACL.Command_Name & " <host> <port> <nick>");
		LLU.Finalize;
	when Constraint_Error =>
		ATIO.Put_Line("ERROR: Port must be an integer");
		LLU.Finalize;
end c4_client;
