# log4shell_scanner
Quick and dirty scanner, hitting common ports looking for Log4Shell (CVE-2021-44228) vulnerability

This utilizes wget, curl, nmap, and the Log4Shell Huntress LDAP endpoint: https://log4shell.huntress.com/

If you need to scan a private subnet that doesn't have internet access, you can stand-up your own HTTP and LDAP server using the source code here: https://github.com/huntresslabs/log4shell-tester
