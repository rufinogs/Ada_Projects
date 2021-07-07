package c4_messages is
type Message_Type is (
	Join, -- C-S Client joins and waits for game to start
	Welcome, -- S-C Client is accepted or rejected
	StartGame, -- S-C New game started
	Server, -- S-C Server info to be displayed by Client
	YourTurn, -- S-C Client is asked to submit a move
	Move, -- C-S Client sends Move
	MoveReceived, -- S-C Server accepts or rejects move
	EndGame, -- S-C Game result sent to Clients
	Logout -- C-S Client quits the game
);
end c4_messages;


