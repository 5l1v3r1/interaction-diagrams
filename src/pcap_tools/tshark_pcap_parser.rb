
class TsharkPcapParser

  @@TSHARK_FIELDS = ["frame.time_epoch", "frame.comment", "tcp.srcport", "tcp.dstport", "http.request.method", "http.request.uri", "http.response.code", "http.response.phrase", "http.user_agent", "http.cookie", "http.set_cookie", "http.location","http.request", "http.response", "http.content_type", "extractor.value.hex" ]

  def self.run(file)
    tshark_command = "tshark -r #{file} -E separator='|' -T fields -X lua_script:./src/extract_bodies.lua -X lua_script1:data-text-lines -X lua_script1:json -X lua_script1:urlencoded-form -e " + @@TSHARK_FIELDS.join(" -e ")
    SystemCommandExecutor.invoke(tshark_command) do |line|
      fields = line.split("|")

      def fields.[](key)
        fetch(key).presence
      end

      if (fields[12] == "1" || fields[13] == "1")
        payload = {"time" => fields[0],
               :pid => extract_pid(fields[1]),
               :pcap_src_port => fields[2],
               :pcap_dst_port => fields[3],
               :method => fields[4],
               :path => fields[5],
               :code => fields[6],
               :phrase => fields[7],
               :user_agent => fields[8],
               :cookie => fields[9],
               :set_cookie => fields[10],
               :location => fields[11],
               :request_or_response => request_or_response(fields[12], fields[13]),
               :content_type => fields[14],
               :body => [fields[15]].pack('H*')
            }
            yield payload
      end
    end
  end

  def self.extract_pid(field)
    field[/(\d+)/] if field
  end

  def self.request_or_response(request_flag, response_flag)
    if (request_flag == "1")
      "request"
    elsif (response_flag == "1")
      "response"
    else
       ""
     end
  end

end
