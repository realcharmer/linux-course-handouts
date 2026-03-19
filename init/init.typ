#import "@preview/marginalia:0.3.1" as marginalia: note, notefigure, wideblock
#import "@preview/oxdraw:0.1.0": *
#import "config.typ": config

#set document(title: "Boot & Init Systém")

#show: marginalia.setup.with(
  inner: (far: 1cm, width: 0cm, sep: 1cm),
  outer: (far: 1cm, width: 5cm, sep: 1cm),
  top: 2cm,
  bottom: 2cm,
)
#show: config

#title()


= Boot Proces

#wideblock(side: "both")[
#oxdraw("
graph LR
    POST --> BIOS/UEFI
    BIOS/UEFI --> Bootloader
    Bootloader --> initrd
    Bootloader --> Kernel
    Kernel --> Init
    initrd --> Kernel
    Init --> Services
")
]

1. *BIOS/UEFI* -- Po zapnutí počítače firmware (BIOS nebo modernější UEFI) provede kontrolu hardwaru (POST) a~vybere zařízení, ze kterého se bude bootovat.
2. *Bootloader* -- Bootloader#note[Typicky GRUB] se načte z~disku a~umožní vybrat operační systém nebo jádro. Poté nahraje Linuxové jádro (kernel) a~initramfs do paměti.
3. *Linux kernel* -- Jádro se rozbalí, inicializuje paměť, CPU, ovladače a~připojí dočasný kořenový souborový systém (initramfs).
4. *initramfs* -- Dočasné prostředí, které připraví skutečný root filesystem (např. odemkne LUKS#note[LUKS je běžný způsob šifrování blokových zařízení, tj. paměťových disků.] oddíly, připojí disk) a~předá řízení procesu init.
5. *Init systém* -- Spustí systémové služby, mountuje souborové systémy, nastaví síť a~spustí login (TTY nebo display manager).

= Init

Init je proces s~*ID 1*, který se spustí jako úplně první při startu systému a~má na starosti inicializaci celého systému. Spouští služby, nastavuje běhové režimy a~dohlíží na ostatní procesy.

Dnes je klasický init ve většině distribucí nahrazen modernějším systémem _systemd_, který plní stejnou roli, jen efektivněji, ale zároveň složitěji. Není však ojedinělý a~*lze se setkat i~s~jinými Init systémy*#note[https://wiki.gentoo.org/wiki/Comparison_of_init_systems].

```sh
$ ps -p 1
  PID TTY          TIME CMD
    1 ?        00:00:00 runit
```

Výstup tohoto příkladu ukazuje proces s~*PID 1*, což je v~tomto případě systém _runit_#note[_runit_ je výchozím Init systémem v~distribuci #link("https://voidlinux.org/")[Void Linux].].

== Runlevels

Runlevely#note[U moderních distribucí používajících _systemd_ se runlevely nahrazují tzv. _targets_, které plní stejný účel.], nebo-li "běhové režimy", jsou předem definované režimy systému, které určují, jaké služby a~procesy mají být spuštěny, nebo jak se má systém chovat. Tradičně se používají runlevely 0--6.

Runlevel lze změnit příkazem `init <runlevel>`. Například restart systému odpovídá runlevelu 6:
#notefigure[
  #block(
    stroke: .5pt + luma(85%),
    inset: 5pt,
    radius: 5pt
  )[
    #table(
      stroke: none,
      columns: 2,
      align: (right, left),
      table.header[*Level*][*Význam*],
      [0], [halt],
      [1], [single user mode],
      [2], [multi-user mode],
      [3], [multi-user mode + networking],
      [4], [],
      [5], [X11],
      [6], [reboot],
    )
  ]
]

```
# init 6
```

= Služby (daemons)

  Konfigurace démonů v~Linuxu závisí na typu init systému. U~klasických init systémů se spouštěcí skripty nacházejí v~adresáři `/etc/init.d/` a~určují, jak se jednotlivé služby#note[Službou mohou být například webserver, cron, docker, bluetoothd atp.] spouští, zastavují nebo restartují.

Moderní systémy se _systemd_ používají unit soubory uložené v~`/etc/systemd/system/` nebo `/lib/systemd/system/`, kde je definováno, jak se služba spouští, restartuje a~zda-li závisí na jiných službách.

== Ovládání služeb

#wideblock[
  #table(
    stroke: none,
    columns: 4,
    table.header[][*systemd*][*OpenRC*][*runit*],
    [Start], [`systemctl start ?`], [`rc-service ? start`], [`sv start ?`],
    [Stop], [`systemctl stop ?`], [`rc-service ? stop`], [`sv stop ?`],
    [Restart], [`systemctl restart ?`], [`rc-service ? restart`], [`sv restart ?`],
    [Reload], [`systemctl reload ?`], [`rc-service ? reload`], [`sv reload ?`],
    [Autostart], [`systemctl enable ?`], [`rc-update add ?`], [`symlink do /etc/service`],
  )
]

Příkaz `restart` službu úplně zastaví a~znovu spustí a~dojde tedy ke krátkému výpadku, zatímco `reload` jen znovu načte její konfiguraci bez zastavení běžícího procesu (pokud to služba podporuje), takže obvykle nedojde k~přerušení provozu.

Použití příkazu `reload` je obecně bezpečnější při změnách konfigurace, protože pokud nová konfigurace obsahuje chybu, služba obvykle pokračuje v~běhu s~původním, funkčním nastavením. Naproti tomu při použití `restart` se služba nejprve zastaví a~následně se pokusí spustit s~novou konfigurací. Pokud je však tato konfigurace neplatná, služba se již nespustí a~zůstane ve vypnutém stavu, což může vést k~delšímu výpadku.
