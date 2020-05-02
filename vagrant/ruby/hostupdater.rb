#!/usr/bin/env ruby

def getWebHosts(cfg)

    vhosts = {
        "apache" => cfg.has_key?("apache") && cfg["apache"].has_key?("hosts") ? "#{cfg["apache"]["hosts"]}" : false,
        "nginx" => cfg.has_key?("nginx") && cfg["nginx"].has_key?("hosts") ? "#{cfg["nginx"]["hosts"]}" : false,
    }

    puts vhosts
end
