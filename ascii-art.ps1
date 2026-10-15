## ASCII art collection.
## $Art is a hashtable of name -> art string. Add a new piece with another
## key below (single-quoted here-string keeps the art literal). The startup
## banner (10_ascii_art.ps1) picks a random one; Motd-AsciiArt also uses it.

$Art = @{
  GrimReaper = @'

               ...
             ;::::;
           ;::::; :;
         ;:::::'   :;
        ;:::::;     ;.
       ,:::::'       ;          OOO\
       ;:::::;       ;        OOOOOOOO
       ::::::;       ;         OOOOO\
      ,;::::::;     ;'       / OOOOOOO
    ;:::::::::. ,,,;.       /  / DOOOOOO
  .';:::::::::::::::::;,   /  /     DOOOO
 ,::::::;::::::;;;;::::;, /  /        DOOO
;::::::'::::::;;;::::: ,#/  /          DOOO
::::::::;::::::;;::: ;::#  /            DOOO
:::::::::;:::::::: ;::::# /              DOO
::::::::;:::::: ;:::::::#/               DOO
 ::::::::::;; ;:::::::::##                OO
 :::::::::::;::::::::;:::#                OO
 :::::::::::::::::;':;:::#                O
  :::::::::::::;' /  / :#
   :::::::::::;' /  /   #
'@

  AlienFlamethrower = @'

                                         )  (  (    (
                                         (  )  () @@  )  (( (
                                     (      (  )( @@  (  )) ) (
                                   (    (  ( ()( /---\   (()( (
     _______                            )  ) )(@ != =! )@@  ( ) ) )
    <   ____)                      ) (  ( )( ()@ \(-)/ (@@@@@ ( ()( )
 /--|  |( //|                     (  )  ) ((@@(@@ !o! @@@@(@@@@@)() (
|__|>   \___|                      ) ( @)@@)@ /---\-/---\ )@@@@@()( )
|  /--------+\                    (@@@@)@@@( // /-----\ \\ @@@)@@@@@(  .
| |    \ =========______/|@@@@@@@@@@@@@(@@@ // @ /---\ @ \\ @(@@@(@@@ .  .
|  \   \\=========------\|@@@@@@@@@@@@@@@@@ O @@@ /-\ @@@ O @@(@@)@@ @   .
|  |\   \----+--\-)))           @@@@@@@@@@ !! @@@@ % @@@@ !! @@)@@@ .. .
|  ||\______|_)))/             .    @@@@@@ !! @@ /---\ @@ !! @@(@@@ @ . .
 \_/\\========/           *        .    @@ /MM  /\O   O/\  MM\ @@@@@@@. .
    |//  /^\  \\          (       .      @ !!!  !! \-/ !!  !!! @@@@@ .
    //. /   \  \\          )   -cfbd-   .  @@@@ !!     !!  .(. @.  .. .
    [_]`    |/[_]        (    /   .(  . \)). ( |O  )( O! @@@@ . )      .
    | /|    /\_/         ) (      )).  ((  .) !! ((( !! @@ (. ((. .   .
    | ||   /_//   ()  ))   ))   .( ( ( ) ). ( !!  )( !! ) ((   ))  ..
   /\=_\_ <\=_\   ( ) ( (  ) )   (( )  )).) ((/ |  (  | \(  )) ((. ).
__<\_\_[_| \\__\(___)_))_((_(____))__(_(___.oooO_____Oooo.(_(_)_)((_
'@

  Foxbody = @'

                     .-+=======---::..
                   :=+##@@@@@@@@@@@@@%@@@#.
                .=:*=@#@@@@@@%@@@@@@@@@@@@%+.      ..
  ...::..    .:+.*=%%%@@@@@@*%@@@@@@@@@@@@@%#-.    ..
 .%@@@%%%%*--=.=*+@#@@@@@@@@=#@@@@@@@@@@@@@@@##-.:..:
 *@@@@@@@@@@@@@=%@##%%#####*+%%#%%%%%%%%%%%@@@@*%#@%%#*+=:..
=%#....................:::::::--:-+#@@@@@@@@@@@@@#*%@@@@@%%#+=+*+:.
#@@*=-:-::.-@@#**%@@-.       +%%.    .... . ...............:-=+#%@@%+:.
 #%@@@@@@@%*@@@@@@@@=.#@@@@%@@@@@@@%%%%%###*=:-:......  .#%%##%=.    .:=.
#%###**++++@@@@+::-#@@@:---==++***###%%%%@@@@@@#%*@@@@@@:*@@@@@@#+%%+==#@.
=@@@@@@@@@@@@*.     :@@@@@@@@@@@%%%%%##****+++=---:::..:@@@%-:=@@@-::::..
=#*++@@@@@@@. :@@%. =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=    .*@@@@@@@@@-
  .:=#%@@@@%. =@@@: =@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#..@@=.:@@@@@@@@:.
          .@=  .:. .%%++:..:::::::::--------===#%%%%%%%@#..%@-.:@%%%%%=
           .%#:. .=@%.                                 -@+    .**.
            .:#@@@#-.                                   -@@+=*@+.
                                                         ..--:.
'@

  Saturn = @'
                                                     ___
                                                  ,o88888
                                               ,o8888888'
                         ,:o:o:oooo.        ,8O88Pd8888"
                     ,.::.::o:ooooOoOoO. ,oO8O8Pd888'"
                   ,.:.::o:ooOoOoOO8O8OOo.8OOPd8O8O"
                  , ..:.::o:ooOoOOOO8OOOOo.FdO8O8"
                 , ..:.::o:ooOoOO8O888O8O,COCOO"
                , . ..:.::o:ooOoOOOO8OOOOCOCO"
                 . ..:.::o:ooOoOoOO8O8OCCCC"o
                    . ..:.::o:ooooOoCoCCC"o:o
                    . ..:.::o:o:,cooooCo"oo:o:
                 `   . . ..:.:cocoooo"'o:o:::'
                 .`   . ..::ccccoc"'o:o:o:::'
                :.:.    ,c:cccc"':.:.:.:.:.'
              ..:.:"'`::::c:"'..:.:.:.:.:.'
            ...:.'.:.::::"'    . . . . .'
           .. . ....:."' `   .  . . ''
         . . . ...."'
         .. . ."'
        .
'@

  Rat = @'
             xxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx     __
        xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx// \
       xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx((_  )x
      xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_xxxxx
     xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx(o)xxxxxxx
    rrxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo
   rrrxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/|\xx/
  rrrrxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx__/x| \
 rrr   xwxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
rrr      wwwxxxxxxxxx ..                    xwwww...
rrr        wwwxxxxxxx .                       www ..
rrr          wwwww  .....                      ====...
 rrr          =========
  rrr
   'rr._
     ''rrrrrrrrrrrrrrrr
'@

}
