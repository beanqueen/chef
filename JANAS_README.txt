1. in /chef/bin ./chef ausführen
2. in /etc/hosts  127.0.1.1 gnurpsi.local gnurpsi
3. nach einem fehler folgendes ausführen rm nodes/jana.json
4. falls benötigt: die liste der zu installierenden pakete ist in cookbooks/linux/attributes/debian.rb
5. in case of root problems, it might be necessary to do
     sudo: no tty present and no askpass program specified
     Granting the user to use that command without prompting for password should resolve the problem. First open a shell console and type:
     sudo visudo
     Then edit that file to add to the very end:
     username ALL = NOPASSWD: /fullpath/to/command, /fullpath/to/othercommand
  or install yourself
