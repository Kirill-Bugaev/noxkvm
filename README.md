# noxkvm

This project under development.

# Sever
## Parent
1. Fork to background
2. Start net server
3. Open unix domain socket(udsocket) for communication with children
4. Fork -> Child 1
5. Main loop
	1. Accept net connections from clients
	2. if (child not connected) then
		Accept local connection from Child
	3. if (Child connected)
		1. Read from udsocket
		2. if (Child want to die) then
			Read key_code
				if (key_code == current_host or key_code == not_connected_host) then
					Start Child 1
				else
					Start Child 2	
	(4. Examine connected client) (examine only this which switchs to)
		if (some_client closed connection) then
			Remove some_client from table
			if (no clients for running Child 2) then
				1. Kill Child 2
				2. Start Child 1
	5. Go to 1			

## Child 1
1. Start not exclusive grabber on pipe
2. Connect to Parent
3. Read from pipe
4. if (key_code == switch_key_code) then
	1. Send key_code to Parent
	2. Get response from Parent
		if (response == die) then
			Die
5. Go to 3

## Child 2
1. Start exclusive grabber on pipe
2. Connect to Parent
3. Read from pipe
4. if (key_code == switch_key_code) then
	1. Send key_code to Parent
	2. Get response from Parent
		if (response == die) then
			Die
5. Send RAW data to current clients
6. If (some_client closed connection)
	1. Send this client IP to parent
	2. Get response from parent
		if (response == die) then
			Die
7. Go to 3	
			
