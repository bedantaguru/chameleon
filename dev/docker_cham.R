


dc <- stevedore::docker_client()
dc$image$pull("igayen/privoxy-proton")
dc$image$pull("dperson/torproxy")


dt <- dc$container$run(
  image = "dperson/torproxy", name = "TorProxy",
  ports =c("8228:8118"), detach = TRUE, rm = TRUE)


what_is_my_ip <- function(proxy_port, proxy_host = "localhost", proxy_url){
  is_proxied <- FALSE

  final_proxy_url <- ""

  if(!missing(proxy_port)){
    is_proxied <- TRUE
    final_proxy_url <- paste0(proxy_host,":",proxy_port )
  }

  if(!missing(proxy_url)){
    is_proxied <- TRUE
    final_proxy_url <- proxy_url
  }

  if(is_proxied){
    h <- curl::new_handle(proxy = final_proxy_url, verbose = TRUE)
    req <- tryCatch(
      suppressMessages(
        curl::curl_fetch_memory("https://api.ipify.org/?format=json", handle = h)
      ),
      error = function(e) list(content= raw(0)))
  }else{
    req <- tryCatch(
      suppressMessages(
        curl::curl_fetch_memory("https://api.ipify.org/?format=json")
      ),
      error = function(e) list(content= raw(0)))
  }

  tryCatch({
    u <- jsonlite::fromJSON(rawToChar(req$content))
    u$ip
  }, error = function(e) NULL)
}



# trying HA
# with privoxy
# unable to do

#  to edit
#  docker run -d -it --device=/dev/net/tun --cap-add=NET_ADMIN -p 8448:8080 -e PVPN_CMD_ARGS="connect --fastest" -e PVPN_PROTOCOL="udp" -e PVPN_TIER=0 -e PVPN_USERNAME="user" -e PVPN_PASSWORD="pass" --name privoxy-proton igayen/privoxy-proton
# and follow https://www.thegeekdiary.com/how-to-update-add-a-file-in-the-docker-image/
# Eventually run
# docker commit -m="Update PVPN" privoxy-proton igayen/privoxy-proton
# Then push it (optional)



# below not working
# mostly something to do with the docker
proto <- dc$container$run(
  image = "igayen/privoxy-proton",
  name = "ProtonPrivoxy",
  ports =c("8448:8080"),
  env = list(`PVPN_CMD_ARGS` = "connect --fastest",
             `PVPN_PROTOCOL` = "udp",
             `PVPN_TIER` = 0L,
             `PVPN_USERNAME` = "",
             `PVPN_PASSWORD` = ""),
  host_config = list(`cap_add` = "NET_ADMIN"),
  detach = TRUE, rm = TRUE)

dt1 <- dc$container$run(
  image = "dperson/torproxy", name = "TorProxy1",
  ports =c("8228:8118"), detach = TRUE, rm = TRUE)

dt2 <- dc$container$run(
  image = "dperson/torproxy", name = "TorProxy2",
  ports =c("8338:8118"), detach = TRUE, rm = TRUE)
