# Instalace


Naklonovat projekt z Githubu a spustit příkaz Make. 

    make

Je třeba také nainstalovat [skripty pro práci s XML z
Alephu](https://github.com/michal-h21/prirustak).


# Zpracování objednávek z Alephu

Aleph tvoří dávky s novýma objednávkama ve všední dny po 8. a pak ve 14:15. Objednávka má název:

    pedfr_obj_sklad_YYYYMMDD_HHMM

takže například

    pedfr_obj_sklad_20200417_1415

Soubor se objeví ve správci souborů v modulu Výpujčky. Je třeba stáhnout. Pokud
spouštím Aleph přes Wine, můžu soubor naimportovat do současného adresáře
pomocí:

    ./aleph-import pedfr_obj_sklad_20200417_1415

Ten opraví konce řádků a nakopíruje soubor do podadresáře objednavky. Pak můžeme vygenerovat seznam objednávek pomocí:

    texlua alephobjednavky.lua objednavky/pedfr_obj_sklad_20200417_1415

PDF soubor bude vygenerován v adresáři `objednavky` a automaticky se zobrazí. 

# Odesílání mailů

Kromě PDF souboru se vygeneruje také CSV soubor, který jde otevřít v Excelu. Ten se využije pro hromadné odesílání mailů. 

## Prerekvizity

- nastavit účet pro knihovnu v thunderbirdu
- nainstalovat rozšíření [MailMerge](https://addons.thunderbird.net/en-US/thunderbird/addon/mail-merge/)

## Postup

- návod na použití CSV souboru pro hromadných mailů na stránkách rozšíření [MailMerge](https://addons.thunderbird.net/en-US/thunderbird/addon/mail-merge/)
- otevřít CSV soubor v Excelu a smazat záznamy, které se nevyřídily. Ty se musí vykomunikovat ručně.
- pole z CSV souboru se můžou vložit do mailu (do adresy, předmětu i těla) pomocí {{jmeno pole}}.
- příklad:

```
adresa: {{mail}}
předmět: Knihovna PedF UK. Vyřízená objednávka č. {{id}}
text: 
Dobrý den, 
      
vaše objednávka č. {{id}} z {{submitDate}} byla vyřízena. 

Připravili jsme pro Vás signatury: {{calno}}.

```

- místo "Odeslat" je třeba kliknout na šipku dolů a vybrat *Mail Merge*
- otevře se dialog. Jako zdroj vybrat "CSV", najít soubor pomocí procházet. Jako oddělovač polí se musí zadat "Tab". Pak můžeme vybrat OK.
- maily se neodešlou hned, uloží se do složky "Pošta k odeslání". Klikneme na
  ní pravým tlačítkema vybereme "Odeslat neodeslané zprávy". Ale nejdřív můžete
  zkontrolovat, jestli je všechno v pořádku.



# Zpracování objednávkového formuláře na výpůjčky

Vytvořil jsem [formulář v Office
365](https://forms.office.com/Pages/ResponsePage.aspx?id=laM1U3A3v0GxEVnvrgi_jU6f05kDVOhKt8FsX90w7ndUNjk3MlU1UkpTS0tHMFBWWFFNNTJJWUI2My4u),
který posílá odpovědi ve formátu JSON na mail. Došlé maily se můžou
vyexportovat do CSV souboru v Tunderbirdu pomocí pluginu [Import Export
Tools](https://addons.thunderbird.net/en-US/thunderbird/addon/importexporttools/). CSV soubor se zpracuje pomocí skriptu v tomto repozitáři
a vytvoří se PDF s objednávkovými formuláři.
