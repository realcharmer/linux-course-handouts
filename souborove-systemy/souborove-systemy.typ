#import "@preview/marginalia:0.3.1" as marginalia: note, notefigure, wideblock
#import "@preview/oxdraw:0.1.0": *
#import "config.typ": config

#set document(title: "Souborové Systémy")

#show: marginalia.setup.with(
  inner: (far: 1cm, width: 0cm, sep: 1cm),
  outer: (far: 1cm, width: 5cm, sep: 1cm),
  top: 2cm,
  bottom: 2cm,
)
#show: config

#title()


Souborový systém je způsob organizace dat na blokových zařízeních.#note[
  Dnes běžné souborové systémy:

  - ext4
  - XFS
  - BTRFS
  - ZFS
]

Slouží jako abstrakce pro uživatele, který používá adresáře a~soubory a~samotná organizace dat na disku je před ním skrytá.

Souborový systém je tedy stromová struktura s~metadaty, jako jsou oprávnění, časová razítka nebo vlastnictví. Mezi základní úlohy patří správa diskového prostoru a zajištění integrity dat.

Moderní souborové systémy se snaží vyvážit výkon, spolehlivost a škálovatelnost. Musí být schopné zvládat situace jako výpadek napájení nebo pád systému bez poškození dat. K~tomu využívají různé techniky a pokročilé vlastnosti.


= Vlastnosti souborových systémů

*Inode* je základní datová struktura v~mnoha souborových systémech#note[Například ext4 nebo ZFS], která obsahuje *metadata* souboru, jako jsou oprávnění, vlastník, časová razítka a ukazatele na bloky dat souboru.#note[Počet inode je pevně stanoven. Může nastat situace, kdy na blokovém zařízení je volné místo, ale nezbývá žádný volný inode. Obecně jsou systémy nastavené tak, aby k~tomuto případu nedocházelo.] *Název souboru není součástí metadat*.

```bash
$ df -i /dev/nvme0n1
Filesystem      Inodes IUsed   IFree IUse% Mounted on
devtmpfs       4074440   578 4073862    1% /dev
```

*Žurnálování* je technika pro zvýšení konzistence a zjednodušení obnovy po chybě. Před provedením změn se zamýšlené operace zaznamenají do žurnálu.#note[V~případě pádu systému lze tyto operace znovu provést nebo vrátit zpět, což minimalizuje riziko poškození dat.]

*Copy-on-write* (CoW) znamená, že data nejsou přepisována na stejném místě, ale zapisují se na nové bloky. Metadata se následně aktualizují tak, aby ukazovala na novou verzi dat.#note[CoW zvyšuje spolehlivost, umožňuje vytváření snapshotů a zabraňuje částečným zápisům. Může však vést k~fragmentaci a vyšší režii.]

*Snapshoty* jsou konzistentní kopie souborového systému nebo svazku v~určitém okamžiku. Umožňují rychlý návrat do předchozího stavu bez nutnosti kompletního zálohování.#note[V~souborových systémech s~CoW jsou snapshoty velmi efektivní.]

*Deduplikace* je proces identifikace a odstranění duplicitních datových bloků. Místo ukládání několikrát stejného obsahu systém uchovává jednu kopii a další odkazy jsou pouze referencí na tuto jedinou kopii.#note[Deduplikace šetří místo na disku, ale může zvýšit nároky na procesor a~paměť. Obecně se doporučuje deduplikaci používat jen v~případě, že bude existovat tři a~více kopií.]

*Komprese* je technika pro snížení velikosti uložených dat. Data jsou ukládána v~komprimované podobě a dekomprimována při čtení.

*Scrub* je údržbová operace, při které souborový systém prochází všechny bloky dat a kontroluje jejich integritu pomocí kontrolních součtů. Pokud jsou nalezeny chyby, mohou být opraveny z~redundantních kopií. Scrub slouží k~prevenci tichých chyb a dlouhodobému zajištění spolehlivosti dat.#note[Scrub je běžně spouštěn v~delších intervalech, například jednou za měsíc.]

*Resilvering* je proces obnovy dat na poškozeném nebo nově přidaném disku ve svazku s~redundancí, například v~ZFS nebo RAID. Při resilveringu jsou chybějící nebo poškozené bloky rekonstruovány ze zbývajících redundantních dat, aby se zajistila integrita celého svazku.


= Sybmolic & Hard Links

*Hard link* umožňuje vytvořit nový odkaz na stávající inode. Nevzniká tím nový objekt, ale využívá se stejný inode.#note[Odkazy na adresáře jsou zakázány z~důvodu možného vzniku smyček.]

#wideblock(side: "inner")[
```bash
$ echo "Hello World!" > file.txt
$ ln file.txt link.txt
$ ls -li
total 8
37946717 -rw-r--r-- 2 em em 13 Mar 19 11:06 file.txt
37946717 -rw-r--r-- 2 em em 13 Mar 19 11:06 link.txt
```
]

V~tomto příkladu má _inode ID_ hodnotu `37946717` a~zároveň číslo `2` specifikuje počet odkazů na daný inode. Bude li smazán jeden z~těchto souborů, data zůstanou na disku uložena.

Oproti tomu *Symbolic Link*#note[Nebo také _Soft Link_] vytvoří *nový objekt s~jiným inode*. Tento inode však obsahuje cestu k~původnímu souboru.

#wideblock(side: "inner")[
```bash
$ echo "Hello World!" > file.txt
$ ln -s file.txt link.txt
$ ls -li
total 8
37946888 -rw-r--r-- 1 em em 13 Mar 19 11:17 file.txt
37946890 lrwxrwxrwx 1 em em  8 Mar 19 11:18 link.txt -> file.txt
```
]

Zde má každý soubor svůj vlastní inode. Bude-li smazán zdrojový soubor, na který odkazuje _symlink_, data jsou z~disku samzána a~_symlink_ nebude dále fungovat.#note[Takzvaně _Broken Link_]


= RAID

RAID (Redundant Array of Independent Disks) je technologie pro ukládání dat, která *kombinuje více pevných disků do jednoho logického celku*. Jejím cílem je zlepšit výkon, zvýšit spolehlivost nebo obojí současně. Data se mohou na disky rozdělovat (tzv. striping), zrcadlit (mirroring) nebo doplňovat o~paritní data, díky čemuž může systém pokračovat v~provozu i při selhání některého z~disků. RAID se používá hlavně v~serverech a datových úložištích, ale i v~běžných počítačích tam, kde je důležité zajistit dostupnost systému i při selhání disku.#note[Je důležité však mít na paměti, že *RAID není zálohování dat*; pouze zajišťuje dostupnost.]

= ZFS

#notefigure(
  alignment: "top",
  image("openzfs.png", width: 40%),
)ZFS je pokročilý CoW souborový systém a~správce blokových zařízení navržený s~důrazem na integritu dat, škálovatelnost a jednoduchou správu.


Jednou z~vlastností ZFS je kontrola integrity pomocí kontrolních součtů. Každý blok dat je ověřován při čtení a v~případě chyby může být automaticky opraven, pokud je k~dispozici redundantní kopie. ZFS také podporuje snapshoty, klony, kompresi, deduplikaci a~také replikaci dat na jiné diskové pole.#note[Replikaci lze realizovat i~po síti.]

Součástí ZFS je i správa diskových polí, takže není potřeba samostatný RAID. Nabízí různé úrovně redundance a jednoduchou správu úložiště jako jednoho logického celku. Díky těmto vlastnostem je ZFS vhodný zvláště pro servery s~diskovými poli, kde je důležitá spolehlivost.

== Koncepty ZFS

ZFS je navržený jako kombinace souborového systému a správy blokových zařízení, což přináší několik unikátních konceptů. Základem je *storage pool*, který představuje logický celek z~jednoho nebo více fyzických zařízení. Pool spravuje alokaci prostoru, redundanci a~integritu dat, takže souborový systém už nemusí řešit jednotlivé disky zvlášť. Z~poolu mohou být vytvářeny jednotlivé souborové systémy (datasets) a~svazky (volumes).

#notefigure(
  image("zfs-pools.png", width: 100%),
)*Vdev (virtual device)* se skládá z~jednoho nebo více fyzických disků a~určuje způsob redundance a~ochrany dat, například *zrcadlení* (mirror) nebo *RAID-Z*.

*Pool* je složen z~jednoho či více vdevů a~reprezentuje výsledné úložiště, se kterýým pracuje systém. Lze dety slučovat více různých vdevů do jednoho poolu.

*Datasets & Volumes* umožňují logické oddělení dat uvnitř poolu. Dataset je typicky souborový systém s~vlastními vlastnostmi, snapshoty a~nastaveními, zatímco volume je blokové zařízení, které lze použít například jako backend pro databáze nebo virtuální stroje.

== RAID-Z & Mirror

Jedná se o~napodobení systému RAID přímo v~ZFS, které umí spojit fyzické disky do jednoho _vdevu_.#note[Tyto metody lze různě kombinovat, například využít _stripe_ přes dva mirrory (2x2 mirror).]

*Mirror* provádí zrcadlení dvou disků bez využití paritních bloků. Využívá 50% kapacity disků a~redundance je 1 disk. Při selhání jednoho z~disků a~jeho výměně jsou data jednoduše znovu překopírována.

*RAID-Z* využívá ukládání paritních bloků přes tři a~více disků. Díky této paritě lze dopočítat chybějící data, pokud některý z~disků selže. RAID-Z nabízí tři módy:

- *RAIDZ1*: Kapacita jednoho disku využita na paritní data#note[Podobné RAID5]
- *RAIDZ2*: Kapacita dvou disků využita na paritní data#note[Podobné RAID6]
- *RAIDZ3*: Kapacita tří disků využita na paritní data

Zde je příklad srovnání různých konfigurací, kde disk má kapacitu 1TB:

#wideblock[
#table(
  stroke: none,
  columns: 8,
  [*Disky*], [*Konfigurace*], [*Read IOPS*], [*Write IOPS*], [*Read* _(MB/s)_], [*Write* _(MB/s)_], [*Kapacita*], [*Redundance*],

  [4], [2x2 Mirror], [1000], [500], [400], [200], [2 TB (50%)], [2 (1/VDEV)],
  [4], [1x4 RAID-Z1], [250], [250], [300], [300], [3 TB (75%)], [1],
  [4], [1x4 RAID-Z2], [250], [250], [200], [200], [2 TB (50%)], [2],
  [5], [1x5 RAID-Z1], [250], [250], [400], [400], [4 TB (80%)], [1],
  [5], [1x5 RAID-Z2], [250], [250], [300], [300], [3 TB (60%)], [2],
  [5], [1x5 RAID-Z3], [250], [250], [200], [200], [2 TB (40%)], [3],
)
]

#pagebreak()
#wideblock[
== Práce se ZFS

V~tomto příkladu budeme pracovat se dvěma přidanými disky a~vytvoříme z~nich zrcadlený pool.

#columns(2)[
=== Pool

```bash
zpool create tank mirror /dev/<disk> /dev/<disk>
```

Tímto se vytvoří pool s~názvem "tank", kde jsou data zrcadlena mezi dvěma disky. ZFS automaticky začne spravovat redundanci a~integritu dat.

```bash
zpool status
```

Zobrazí informace o~poolu, včetně stavu disků a~případných chyb.

```bash
zpool list
```

Ukáže základní přehled poolů, jejich velikost a~využití kapacity.

=== Dataset

Vytvoříme nový dataset s~názvem `tank/data`. Datasety jsou reprezentovány ve stromové struktuře.

```bash
zfs create tank/data
```

Dataset funguje jako samostatný souborový systém uvnitř poolu.

```bash
zfs list
```

Ukáže všechny datasety a jejich využití.

#colbreak()
=== Komprese

```bash
zfs set compression=lz4 tank/data
```

Zapne transparentní kompresi pro daný dataset.

=== Snapshoty

Vytvoření snapshotu:

```bash
zfs snapshot 
```

Snapshot zachytí aktuální stav dat.
Výpis snapshotů:

```bash
zfs list -t snapshot
```

Obnovení dat do stavu vybraného snapshotu:

```bash
zfs rollback tank/data@nazev_snapshotu
```

=== Scrub

Scrub spustí kontrolu všech dat a~případnou opravu chyb.

```bash
zpool scrub tank
```
]
]

#wideblock[
#bibliography(
  "sources.yaml",
  style: "iso-690-author-date",
  full: true
)
]
