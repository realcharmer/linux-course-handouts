#import "@preview/marginalia:0.3.1" as marginalia: note, notefigure, wideblock
#import "@preview/oxdraw:0.1.0": *
#import "config.typ": config

#set document(title: "Secure Shell")

#show: marginalia.setup.with(
  inner: (far: 1cm, width: 0cm, sep: 1cm),
  outer: (far: 1cm, width: 5cm, sep: 1cm),
  top: 2cm,
  bottom: 2cm,
)
#show: config

#title()


*SSH* (Secure Shell) je protokol pro bezpečný vzdálený přístup ke vzdálenému systému přes síť. Umožňuje přihlášení do systému, spouštění příkazů nebo přenos souborů.

Komunikace je oproti starším řešením#note[Historicky se pro vzdálený přístup používal protokol _Telnet_. Komunikace není šifrovaná a~proto byl univerzálně nahrazen protokolem SSH.] šifrovaná, takže přenášená data ani přihlašovací údaje nejsou čitelné pro třetí strany.

Na serveru běží služba `sshd` (SSH daemon), která přijímá příchozí SSH spojení. Obecně se používá implementace *OpenSSH* ze softwarového balíku `openssh`, respektive `openssh-server` a~`openssh-client`.


= Konfigurace serveru

Hlavní konfigurace SSH serveru se nachází v~souboru `/etc/ssh/sshd_config`.#note[Po změně konfigurace je nutné službu restartovat.] Zde lze nastavit například:

- Port na kterém server poslouchá
- Zda je povoleno přihlášení root uživatele
- Typy autentizace
- Povolení uživatelé


= SSH Klient

SSH Klient se používá k~připojení na vzdálený server, či vytváření tunelů, viz @tunel. Klient je také ve většině případů součástí softwarového balíku `openssh`. #notefigure(
  image("openssh.png", width: 100%),
  alignment: "caption-top"
)

== Připojení na SSH server

Pro připojení se používá klientský program `ssh`.#note[Standardně používá port *22*.]

```sh
ssh <user>@<server>
```
Případně je možné použít klasické parametry.

```sh
ssh -l <user> -p <port> <server>
```

Při prvním připojení klient uloží otisk serverového klíče do souboru `~/.ssh/known_hosts`.#note[Tento mechanismus chrání proti tzv. _man-in-the-middle_ útokům.] Pokud se otisk serveru na adrese změní, SSH klient se odmítne připojit.

== Konfigurace klienta

Konfigurace klientské části se nachází v~domovské složce kazdého uživatele v~souboru `~/.ssh/config`. Zpravidla obsahuje informace o~vzdálených serverech, aby nebylo nutné manuálně vypisovat například port či cestu ke klíči (viz následující kapitola).


= Klíče

SSH podporuje autentizaci pomocí asymetrických kryptografických klíčů. Skládají se ze dvou částí: *privátní klíč* a *veřejný klíč*. #notefigure(
  image("keypair.png", width: 55%),
  alignment: "caption-top"
)

== Generování klíčů

Klíče lze vytvořit pomocí nástroje `ssh-keygen`.

```sh
ssh-keygen -t ed25519
```

V tomto příkladu je zároveň specificky nastaven typ klíče `ed25519`, což je moderní alternativa k~již zastaralým algoritmům _RSA_ či _ECDSA_. @ed25519

Budou vytvořeny dva soubory: #notefigure(
  image("key-gen.png", width: 50%),
  alignment: "caption-top"
)

- `~/.ssh/id_ed25519` -- *Privátní klíč*
- `~/.ssh/id_ed25519.pub` -- *Veřejný klíč*

*Privátní klíč* by měl být vždy navíc *zašifrován heslem*#note[`ssh-keygen` se automaticky ptá na heslo pro zašifrování privátního klíče.], aby nedošlo k~jeho nechtěnému úniku. Tento klíč má pouze uživatel, který se bude na vzdálený server přihlašovat.

*Veřejný klíč*, jak vyplývá z~názvu, bude veřejně distribuován na cílové servery, které mají provádět autentizaci.

== Instalace veřejného klíče na server

Veřejný klíč musí být uložen na serveru v~souboru `~/.ssh/authorized_keys`. Nejjednodušší způsob je použít nástroj `ssh-copy-id`.

```sh
ssh-copy-id -i <key> <user>@<server>
```

Je ovšem možné ručně zkopírovat obsah veřejného klíče na cílový server do souboru `~/.ssh/authorized_keys`. Po úspěšné instalaci je možné se přihlašovat pomocí klíče. #notefigure(
  image("signatures.png", width: 70%),
  alignment: "caption-top"
)

```sh
ssh -i <key> <user>@<server>
```

= SSH Agent

SSH agent bezpečně uchovává privátní klíče v paměti a~umožňuje je používat pro přihlašování bez nutnosti pokaždé zadávat heslo k~privátnímu klíči.#note[Je součástí balíku `ssh-client`.] Lze jej spustit následujícím příkazem.

```sh
eval $(ssh-agent -s)
```

Proces `ssh-agent` poté ukládá všechny klíče, které jsou uživatelem následovně odemčeny. To si lze ověřit opětovných připojením na vzdálený server -- uživatel nebude opětovně dotázán na heslo k privátnímu klíči.

= Zabezpečení

== Vynucení přihlášení pomocí klíčů

Dobrou praxí je vždy zakázat přihlášení heslem a~pro autentizaci povolit pouze klíče.

```
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

== Povolené šifry

SSH server může vynutit používání specifických algoritmů#note[Vynucení moderních algoritmů však vyžaduje kompatibilní verzi SSH. U~starších systémů nemusí být tyto šifry dostupné.], například:

#wideblock[
```
KexAlgorithms sntrup761x25519-sha512@openssh.com,mlkem768x25519-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms ssh-ed25519
PubkeyAcceptedAlgorithms ssh-ed25519
```
]


= Jump Hosts

Jump Host#note[Někdy známý pod názvem _bastion host_.] je server, přes který se připojujeme do jiné, často interní sítě. Používá se například tehdy, když cílový server není dostupný přímo z~Internetu.#note(numbering: none)[
#oxdraw("
graph TD
    Client --> Jump Host
    Jump Host --> |VPN Tunel|Server
")
]

Připojení lze realizovat pomocí parametru `-J`.

```sh
ssh -J <user>@<jumphost>[:port] <user>@<server>
```

Nejprve se vytvoří SSH spojení na jump host a~poté z~něj spojení na cílový server. Jump host lze také definovat v~konfiguraci SSH klienta.

```
Host jump-host
    HostName <address>
    User <user>

Host destination-server
    HostName <address>
    User <user>
    ProxyJump jump-host
```

Je zároveň možné řetězit více hostů a~tím vytvořit komplexní tunel.

#wideblock[
```sh
ssh -J <user>@<jumphost-0>,<user>@<jumphost-1>,<user>@<jumphost-2> <user>@<server>
```
]


= SSH tunelování<tunel>

SSH umožňuje vytvářet šifrované tunely pro přenos jiných síťových služeb. Tím lze bezpečně přenášet například webový provoz nebo databázové spojení.

== Lokální tunel

Lokální port na klientovi je přesměrován na vzdálený server.

```sh
ssh -L 8080:localhost:80 <user>@<server>
```

Po navštívení adresy `localhost:8080` na klientovi se požadavek přenese na port `80` na serveru.

== Vzdálený tunel

Server může zpřístupnit port na klientovi skrze server.

```sh
ssh -R 9000:localhost:3000 <user>@<server>
```

Tento mechanismus se často používá při remote debuggingu nebo zpřístupnění lokální služby přes vzdálený server.


#wideblock[
#bibliography(
  "sources.yaml",
  style: "iso-690-author-date",
  full: true
)
]
