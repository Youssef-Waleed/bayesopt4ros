[~,hostname] = system('hostname');
hostname = string(strtrim(hostname));
address = resolvehost(hostname,"address");
portNumber=5000;
% Created Server
server = tcpserver(address,portNumber,"ConnectionChangedFcn",@connectionFcn)
function connectionFcn(src, ~)
%Client is connected
if src.Connected
    disp("Client connected")
    %Read Write infinitly with connected client
    while true
        readData = read(src,src.NumBytesAvailable,'string');
        disp(readData);
        write(src,"Bye Bye","string");
        %Sleep for 5 millisecond
        java.lang.Thread.sleep(5);
    end
end
end
