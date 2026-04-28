# Devops Learnings

## Strategy Tips
- **CGNAT setups**: Always verify both DNAT and FORWARD chains after port forwarding changes → iptables-save + packet counters tell the whole story → Prevents hours of debugging asymmetric routing
- **DNS changes**: Flush DNS cache AND wait 5 min after changing DNS records → Changes propagate slowly and caching masks the real state → Use `dig @8.8.8.8` to verify directly
- **Firewall changes**: After any UFW/iptables change, verify with `sudo ufw status numbered` AND `sudo iptables -L -n -v` → UFW and iptables can diverge, and both must be correct

## Recovery Tips
- **WireGuard DNAT, 0 FORWARD packets**: Asymmetric routing on CGNAT → Switch from MASQUERADE to SNAT in iptables POSTROUTING → Prevents by ensuring reply traffic flows correctly
- **Docker container unreachable from LAN**: `--network host` + iptables interference → Route through nginx reverse proxy on localhost → Always verify with `ss -tlnp` that container is actually listening before debugging nginx
- **Certbot fails**: Usually port 80 occupied or DNS not pointing to correct server → Check `nginx -t`, `curl -4 ifconfig.me` on target, `dig` for DNS → Kill any process on port 80, verify DNS first
- **Ollama crash after firewall change**: UFW rules can block Ollama's localhost port → Always whitelist 11434/tcp from localhost → NEVER modify networking without checking cascading effects (from experience)

## Optimization Tips
- **Debugging network routing**: `mtr` > `traceroute` for pinpointing where packets drop → MTR shows ongoing stats, traceroute is one-shot → `mtr -rwzbc 50 <target>` for comprehensive path analysis
- **Checking service health**: `systemctl status <service>` + `journalctl -u <service> -n 50` together → Status alone doesn't show recent errors → Always check both
- **Docker compose debugging**: `docker compose logs <service> --tail 50` before restarting → Logs often reveal the actual issue (config error, port conflict) → Faster than restart-and-hope