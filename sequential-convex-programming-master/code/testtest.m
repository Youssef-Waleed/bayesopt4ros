[~,hostname] = system('hostname');
hostname = string(strtrim(hostname));
address = resolvehost(hostname,"address");
portNumber=5000;
% Created Server
server = tcpserver(address,portNumber)

    while true
        if server.Connected > 0
            my_doubles = [1.23, 4.56, 7.89, 4.23];

            % Convert to Python list
            python_list = typecast(my_doubles, 'double');
            % A client has connected
            % Get the first connected client
            write(server, my_doubles, "double");
            % Process the data as needed ...

            % Close the connection (if desired) client.close();

            % Break out of the loop
            break;
        end

        % Sleep for a short interval before checking again
        pause(0.1);
    end
list = read(server,3,"double");
disp(list)
delete(server);
% arrayToSend = [1, 2, 3, 4, 5];
% 
% % Send the length of the array first
% write(server, uint32(length(arrayToSend)), 'uint32');
% 
% % Send the array data
% write(server, arrayToSend, 'double');
% 
% disp('Array sent to client.');

