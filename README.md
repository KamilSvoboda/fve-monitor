# fve-monitor
Jednoduchý bash skript pro vizualizaci aktuálních hodnot produkce a spotřeby FVE Fronius.

Pracuje se služou běžící na lokální IP adrese sítě, např.
URL="http://192.168.0.11/api/status/powerflow"

Služba vrací JSON skript ve struktuře

        {
            "common": {
                "datestamp": "20.04.2026",
                "timestamp": "21:16:50"
            },
            "inverters": [
                {
                    "CID": 0,
                    "DT": 0,
                    "E_Total": 1510456.4872222221,
                    "ID": 1,
                    "P": 0
                }
            ],
            "site": {
                "BatteryStandby": false,
                "E_Day": null,
                "E_Total": 1510456.4872222221,
                "E_Year": null,
                "MLoc": 0,
                "Mode": "meter",
                "P_Akku": null,
                "P_Grid": 532.3,
                "P_Load": -532.3,
                "P_PV": 0,
                "rel_Autonomy": 0,
                "rel_SelfConsumption": null
            },
            "version": "14"
        }

Klíčové jsou hodnoty
- P_PV = aktuální výkon FVE, maximální hodnota je 6000, minimální je 0
- P_Load = aktuální celková spotřeba domácnosti. Vždy se jedná o zápornou hodnotu.
- P_Grid = aktuální produkce/spotřeba elektřiny ze sítě, nebo do sítě distributora. Kladná hodnota znaměná spotřebu ze sítě, záporná produkce do sítě (přebytek spotřeby domácnosti z produkce FVE)