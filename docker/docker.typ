#import "@preview/marginalia:0.3.1" as marginalia: note, notefigure, wideblock
#import "config.typ": config

#set document(title: "Kontejnery")

#show: marginalia.setup.with(
  inner: (far: 1cm, width: 0cm, sep: 1cm),
  outer: (far: 1cm, width: 5cm, sep: 1cm),
  top: 2cm,
  bottom: 2cm,
)
#show: config

#title()


= Kontejnerizace & Virtualizace

*Virtualizace* je technologie, která umožňuje spustit na jednom fyzickém serveru více virtuálních počítačů (VM). Každý virtuál má *vlastní operační systém a~virtuální hardware*, což jej izoluje od ostatních VM i~od samotného fyzického stroje. Tato izolace však přináší značný overhead, hlavně při I/O operacích.

*Kontejnerizace* umožňuje spouštět aplikace v~lehkých kontejnerech, které sdílejí *kernel hostitele*. Kontejnery obsahují pouze aplikaci a~její závislosti, nikoli celý operační systém, což je činí rychlejšími a~méně náročnými na systémové zdroje než plně virtualizované systémy. Každý kontejner je izolovaný, ale přitom efektivně využívá zdroje hostitelského systému.
#notefigure(
  image("diagram-vm.png", width: 100%),
  caption: "Diagram VM",
)

Hlavní rozdíl mezi těmito dvěma přístupy je tedy v~úrovni izolace a~virtualizace: virtuální stroje virtualizují *hardware*, zatímco kontejnery virtualizují *operační systém a~prostředí aplikace*.
#notefigure(
  image("diagram-container.png", width: 100%),
  caption: "Diagram Kontejneru",
)

== Implementace kontejnerů v~Linuxu

Kontejnery na Linuxu fungují díky kombinaci několika funkcí jádra, které izolují aplikace a~spravují jejich zdroje, aniž by bylo potřeba spouštět celý virtuální stroj. Hlavními mechanismy jsou *namespaces* a~*cgroups*.

*Namespaces* vytvářejí pro každý kontejner izolované prostředí. To znamená, že procesy uvnitř kontejneru mají vlastní pohled na systémové zdroje, jako jsou síťové rozhraní, procesy, souborový systém nebo uživatelé. Například procesy v~jednom kontejneru nevidí ani nemohou ovlivnit procesy v~jiném kontejneru nebo na hostitelském systému.

*Cgroups* (Control Groups) spravují využití zdrojů kontejneru (resource allocation). Umožňují omezit a~sledovat CPU, paměť, disk I/O nebo síťové zdroje pro každý kontejner zvlášť. Díky tomu kontejnery nemohou "vyhladovět" celý hostitelský systém a~lze je efektivně škálovat.

Kontejnery také používají *copy-on-write souborové systémy*, jako je _OverlayFS_, aby sdílely základní systémové soubory mezi kontejnery a~zároveň umožnily, aby každý kontejner mohl své soubory měnit izolovaně.


= Docker

*Docker* je platforma pro tvorbu, distribuci a~správu kontejnerů. Na Linuxu Docker využívá stejné mechanismy Linuxového jádra, které jsou popsané výše.
#notefigure(
  image("docker-logo.png", width: 80%),
)

Docker umožňuje zabalit aplikaci a~její závislosti do jednoho kontejneru, který lze spustit na libovolném Linuxovém hostiteli s~Dockerem bez ohledu na konfiguraci hostitelského systému. Kromě toho Docker poskytuje nástroje pro správu kontejnerů, jako jsou Docker Compose a~Docker Hub#note[Docker Hub není zdaleka jediným repozitářem pro distribuci kontejnerů. V~praxi se lze setkat typicky s~_ghcr.io_ a~dalšími repozitáři.] (repozitář pro sdílení kontejnerů). To vše dělá z~Dockeru praktický nástroj pro vývoj, testování a~provoz aplikací v~kontejnerech.
#note[Existují i~další implementace pro správu kontejnerů, například Podman, LXC, Kubernetes atp.]

== Dockerfile

Dockerfile je textový soubor, který obsahuje sadu instrukcí pro automatizované sestavení kontejnerového obrazu. Definuje například výchozí systém, instalaci závislostí, kopírování aplikačních souborů, nastavení prostředí a příkaz, který se má po spuštění kontejneru vykonat. Zde je příklad takového `Dockerfile`:

```docker
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

Tento Dockerfile vytváří kontejnerový obraz založený na oficiálním obrazu `nginx:alpine`#note[`nginx` je v~tomto případě název kontejneru, zatímco `alpine` je tag verze kontejneru, viz https://hub.docker.com/_/nginx#supported-tags-and-respective-dockerfile-links], tedy lehké verzi webového serveru _Nginx_ postavené na distribuci Alpine Linux.#note[Alpine Linux je díky své malé velikosti a~minimalistickému návrhu velmi vhodnou distribucí pro použití v~kontejnerech.] Nejprve odstraní výchozí obsah adresáře `/usr/share/nginx/html`, poté do něj zkopíruje vlastní soubor `index.html`, který bude sloužit jako hlavní webová stránka. Instrukce `EXPOSE 80` deklaruje, že kontejner naslouchá na portu `80` pro HTTP provoz.#note[`EXPOSE` přidává záznamy do _iptables_ a~tím zajišťuje směrování (port forwarding).]

Samotný obraz lze poté zkompilovat pomocí `docker build`. Pro tento zkompilovaný obraz byl zvolen `helloworld`:

```bash
docker build -t helloworld .
```

== Správa kontejnerů

Námi vytvořený, nebo-li "zbuilděný", image (obraz) s~názvem `helloworld` je teď možné spustit v~kontejneru. Je zde nutné odlišovat název obrazu `helloworld` a~kontejneru (v~následujícím příkladu je zvolen název `doom`).

```bash
docker run --detach --name doom -p 80:80 helloworld
```

Nyní lze zkontrolovat, že kontejner opravdu běží, a~to příkazem `docker ps`, který vypíše všechny spuštěné kontejnery a~důležité informace o~nich:

#wideblock(side: "both")[
  ```bash
  $ docker ps
  CONTAINER ID   IMAGE      COMMAND     CREATED         STATUS         PORTS                NAMES
  3f6554eb7b7c   example   "/docker…"   3 seconds ago   Up 2 seconds   0.0.0.0:80->80/tcp   doom
  ```
]

  Je zde například vidět, že kontejner má směrovaný port `80` z~hostitele na port `80` uvnitř kontejneru. Zároveň toto přesměrování platí pro všechny vnější adresy (označené jako `0.0.0.0`). Zde je možné přístup omezit jen na specifické adresy či rozsahy adres, například `192.168.1.0/24`.

== Compose

`docker-compose.yaml` je konfigurační soubor psaný v~jazyce YAML. Tento soubor popisuje stav kontejneru (nebo sady více kontejnerů) a~Compose umožňuje dle tohoto konfiguračního souboru specifikované kontejnery vytvářet a~spravovat.

Jako jednoduchý příklad lze uvést předchozí ukázku adaptovanou do `docker-compose.yaml`. V~tomto příkladu je dříve použitý příkaz pro spuštění námy "zbuilděného" kontejneru přepsán do YAML formátu:#note[V jednom souboru lze definovat několik různých služeb, např. jeden kontejner pro aplikaci a~druhý kontejner pro databázi.]

```yaml
services:
  helloworld:
  image: helloworld
  container_name: doom
  ports:
    - 80:80
```

Ve výsledku dostaneme stejný kontejner se stejným nastavením, avšak bez nutnosti vypisovat celý příkaz pro jeho spuštění.#note[Přepínač `-d` v~tomto případě implikuje `--deatch`]

```bash
docker compose up -d
```

= Cheatsheet

#show heading: it => {
  set heading(numbering: none)
  block(
  inset: (left: 0pt),
  it.body,
  )
}

#set table(
  stroke: none,
  gutter: 0.2em,
  fill: (x, y) =>
  if x == 0 { rgb("#2495ec") } else { rgb("#f1f2f1") },
  inset: (right: 1.5em),
)

#show table.cell: it => {
  if it.x == 0 {
  set text(white)
  strong(it)
  } else {
  it
  }
}

#wideblock(side: "both")[
  #columns(2, gutter: 2em)[
    #v(.5cm)
    == Ovládání kontejneru
    #v(.3cm)
    #table(
      columns: (auto, 1fr),
      [ps], [seznam bežících kontejnerů],
      [run], [vytvořit a~spustit nový kontejner],
      [pause], [pozastavit],
      [unpause], [spustit ze stavu pauzy],
      [stop], [zastavit],
      [restart], [restartovat],
      [rm], [odstranit (zastavený) kontejner],
      [kill], [zastavit a~odstranit],
      [attach], [připojit na _stdin/stdout/stderr_],
    )
    #colbreak()
    #v(.5cm)
    == Správa obrazů
    #v(.3cm)
    #table(
      columns: (auto, 1fr),
      [pull], [stáhnou obraz z~repozitáře],
      [rmi], [smazat obraz],
      [images], [seznam obrazů],
      [image prune], [odstranit nevyužité obrazy],
      [build], [sestavit obraz],
      [tag], [přidat tag],
      [save], [exportovat obraz do `.tar`],
      [load], [importovat obraz ze souboru],
    )
  ]
]
