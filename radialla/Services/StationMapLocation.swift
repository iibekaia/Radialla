import CoreLocation

/// Display locations only; country capitals never replace broadcaster coordinates.
enum StationMapLocation {
    static func coordinate(for station: Station) -> CLLocationCoordinate2D? {
        if let coordinate = station.coordinate { return coordinate }
        let code = station.countrycode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let key = (code?.isEmpty == false ? code : countryCodes[station.country]) ?? ""
        guard let capital = capitals[key] else { return nil }
        return CLLocationCoordinate2D(latitude: capital.0, longitude: capital.1)
    }

    // Offline capital locations. See research/capital-map-locations.md for provenance.
    private static let capitals: [String: (Double, Double)] = [
        "AD": (42.5, 1.516667), // Andorra la Vella
        "AE": (24.466667, 54.366667), // Abu Dhabi
        "AF": (34.516667, 69.183333), // Kabul
        "AG": (17.116667, -61.85), // Saint John's
        "AI": (18.216667, -63.05), // The Valley
        "AL": (41.316667, 19.816667), // Tirana
        "AM": (40.166667, 44.5), // Yerevan
        "AO": (-8.833333, 13.233333), // Luanda
        "AR": (-34.6, -58.666667), // Buenos Aires
        "AS": (-14.266667, -170.7), // Pago Pago
        "AT": (48.2, 16.366667), // Vienna
        "AU": (-35.283333, 149.216667), // Canberra
        "AW": (12.516667, -70.033333), // Oranjestad
        "AX": (60.0973, 19.9348), // Mariehamn
        "AZ": (40.383333, 49.866667), // Baku
        "BA": (43.866667, 18.416667), // Sarajevo
        "BB": (13.1, -59.616667), // Bridgetown
        "BD": (23.716667, 90.4), // Dhaka
        "BE": (50.833333, 4.333333), // Brussels
        "BF": (12.366667, -1.516667), // Ouagadougou
        "BG": (42.683333, 23.316667), // Sofia
        "BH": (26.233333, 50.566667), // Manama
        "BI": (-3.4264, 29.9306), // Gitega
        "BJ": (6.483333, 2.616667), // Porto-Novo
        "BL": (17.883333, -62.85), // Gustavia
        "BM": (32.283333, -64.783333), // Hamilton
        "BN": (4.883333, 114.933333), // Bandar Seri Begawan
        "BO": (-16.5, -68.15), // La Paz
        "BQ": (12.1443, -68.2655), // Kralendijk
        "BR": (-15.783333, -47.916667), // Brasilia
        "BS": (25.083333, -77.35), // Nassau
        "BT": (27.483333, 89.6), // Thimphu
        "BW": (-24.75, 25.916667), // Gaborone
        "BY": (53.9, 27.566667), // Minsk
        "BZ": (17.25, -88.766667), // Belmopan
        "CA": (45.416667, -75.7), // Ottawa
        "CC": (-12.166667, 96.833333), // West Island
        "CD": (-4.316667, 15.3), // Kinshasa
        "CF": (4.366667, 18.583333), // Bangui
        "CG": (-4.25, 15.283333), // Brazzaville
        "CH": (46.95, 7.433333), // Bern
        "CI": (6.816667, -5.283333), // Yamoussoukro
        "CK": (-21.2, -159.766667), // Avarua
        "CL": (-33.45, -70.666667), // Santiago
        "CM": (3.866667, 11.516667), // Yaounde
        "CN": (39.916667, 116.383333), // Beijing
        "CO": (4.6, -74.083333), // Bogota
        "CR": (9.933333, -84.083333), // San Jose
        "CU": (23.116667, -82.35), // Havana
        "CV": (14.916667, -23.516667), // Praia
        "CW": (12.1084, -68.9335), // Willemstad
        "CX": (-10.416667, 105.716667), // The Settlement
        "CY": (35.166667, 33.366667), // Nicosia
        "CZ": (50.083333, 14.466667), // Prague
        "DE": (52.516667, 13.4), // Berlin
        "DJ": (11.583333, 43.15), // Djibouti
        "DK": (55.666667, 12.583333), // Copenhagen
        "DM": (15.3, -61.4), // Roseau
        "DO": (18.466667, -69.9), // Santo Domingo
        "DZ": (36.75, 3.05), // Algiers
        "EC": (-0.216667, -78.5), // Quito
        "EE": (59.433333, 24.716667), // Tallinn
        "EG": (30.05, 31.25), // Cairo
        "ER": (15.333333, 38.933333), // Asmara
        "ES": (40.4, -3.683333), // Madrid
        "ET": (9.033333, 38.7), // Addis Ababa
        "FI": (60.166667, 24.933333), // Helsinki
        "FJ": (-18.133333, 178.416667), // Suva
        "FK": (-51.7, -57.85), // Stanley
        "FM": (6.916667, 158.15), // Palikir
        "FO": (62.016667, -6.766667), // Torshavn
        "FR": (48.866667, 2.333333), // Paris
        "GA": (0.383333, 9.45), // Libreville
        "GB": (51.5, -0.166667), // London
        "GD": (12.05, -61.75), // Saint George's
        "GE": (41.7151, 44.8271), // Tbilisi
        "GF": (4.9224, -52.3135), // Cayenne
        "GG": (49.45, -2.533333), // Saint Peter Port
        "GH": (5.55, -0.216667), // Accra
        "GI": (36.133333, -5.35), // Gibraltar
        "GL": (64.183333, -51.75), // Nuuk
        "GM": (13.45, -16.566667), // Banjul
        "GN": (9.55, -13.7), // Conakry
        "GP": (15.9985, -61.7255), // Basse-Terre
        "GQ": (3.75, 8.783333), // Malabo
        "GR": (37.983333, 23.733333), // Athens
        "GS": (-54.2833, -36.5), // King Edward Point
        "GT": (14.616667, -90.516667), // Guatemala City
        "GU": (13.466667, 144.733333), // Hagatna
        "GW": (11.85, -15.583333), // Bissau
        "GY": (6.8, -58.166667), // Georgetown
        "HK": (22.25, 114.166667), // Hong Kong
        "HN": (14.1, -87.216667), // Tegucigalpa
        "HR": (45.8, 16.0), // Zagreb
        "HT": (18.533333, -72.333333), // Port-au-Prince
        "HU": (47.5, 19.083333), // Budapest
        "ID": (-6.166667, 106.816667), // Jakarta
        "IE": (53.316667, -6.233333), // Dublin
        "IL": (31.766667, 35.233333), // Jerusalem
        "IM": (54.15, -4.483333), // Douglas
        "IN": (28.6, 77.2), // New Delhi
        "IQ": (33.333333, 44.383333), // Baghdad
        "IR": (35.666667, 51.416667), // Tehran
        "IS": (64.15, -21.95), // Reykjavik
        "IT": (41.9, 12.483333), // Rome
        "JE": (49.183333, -2.1), // Saint Helier
        "JM": (18.0, -76.8), // Kingston
        "JO": (31.95, 35.933333), // Amman
        "JP": (35.683333, 139.75), // Tokyo
        "KE": (-1.283333, 36.816667), // Nairobi
        "KG": (42.866667, 74.6), // Bishkek
        "KH": (11.55, 104.916667), // Phnom Penh
        "KI": (1.316667, 172.966667), // Tarawa
        "KM": (-11.7, 43.233333), // Moroni
        "KN": (17.3, -62.716667), // Basseterre
        "KP": (39.016667, 125.75), // Pyongyang
        "KR": (37.55, 126.983333), // Seoul
        "KW": (29.366667, 47.966667), // Kuwait City
        "KY": (19.3, -81.383333), // George Town
        "KZ": (51.166667, 71.416667), // Astana
        "LA": (17.966667, 102.6), // Vientiane
        "LB": (33.866667, 35.5), // Beirut
        "LC": (14.016667, -61.0), // Castries
        "LI": (47.133333, 9.516667), // Vaduz
        "LK": (6.8941, 79.9025), // Sri Jayawardenepura Kotte
        "LR": (6.3, -10.8), // Monrovia
        "LS": (-29.316667, 27.483333), // Maseru
        "LT": (54.683333, 25.316667), // Vilnius
        "LU": (49.6, 6.116667), // Luxembourg
        "LV": (56.95, 24.1), // Riga
        "LY": (32.883333, 13.166667), // Tripoli
        "MA": (34.016667, -6.816667), // Rabat
        "MC": (43.733333, 7.416667), // Monaco
        "MD": (47.0, 28.85), // Chisinau
        "ME": (42.433333, 19.266667), // Podgorica
        "MF": (18.066667, -63.083333), // Marigot
        "MG": (-18.916667, 47.516667), // Antananarivo
        "MH": (7.1, 171.383333), // Majuro
        "MK": (42.0, 21.433333), // Skopje
        "ML": (12.65, -8.0), // Bamako
        "MM": (19.7633, 96.0785), // Nay Pyi Taw
        "MN": (47.916667, 106.916667), // Ulaanbaatar
        "MP": (15.2, 145.75), // Saipan
        "MQ": (14.6161, -61.0588), // Fort-de-France
        "MR": (18.116667, -16.033333), // Nouakchott
        "MS": (16.7, -62.216667), // Plymouth
        "MT": (35.883333, 14.5), // Valletta
        "MU": (-20.15, 57.483333), // Port Louis
        "MV": (4.166667, 73.5), // Male
        "MW": (-13.983333, 33.783333), // Lilongwe
        "MX": (19.433333, -99.133333), // Mexico City
        "MY": (3.166667, 101.7), // Kuala Lumpur
        "MZ": (-25.95, 32.583333), // Maputo
        "NA": (-22.566667, 17.083333), // Windhoek
        "NC": (-22.266667, 166.45), // Noumea
        "NE": (13.516667, 2.116667), // Niamey
        "NF": (-29.05, 167.966667), // Kingston
        "NG": (9.083333, 7.533333), // Abuja
        "NI": (12.15, -86.283333), // Managua
        "NL": (52.383333, 4.9), // Amsterdam
        "NO": (59.916667, 10.75), // Oslo
        "NP": (27.716667, 85.316667), // Kathmandu
        "NU": (-19.016667, -169.916667), // Alofi
        "NZ": (-41.466667, 174.85), // Wellington
        "OM": (23.616667, 58.583333), // Muscat
        "PA": (8.966667, -79.533333), // Panama City
        "PE": (-12.05, -77.05), // Lima
        "PF": (-17.533333, -149.566667), // Papeete
        "PG": (-9.5, 147.166667), // Port Moresby
        "PH": (14.583333, 121.0), // Manila
        "PK": (33.7, 73.166667), // Islamabad
        "PL": (52.25, 21.0), // Warsaw
        "PM": (46.766667, -56.183333), // Saint-Pierre
        "PN": (-25.066667, -130.083333), // Adamstown
        "PR": (18.466667, -66.116667), // San Juan
        "PT": (38.716667, -9.133333), // Lisbon
        "PW": (7.5006, 134.6242), // Ngerulmud
        "PY": (-25.266667, -57.666667), // Asuncion
        "QA": (25.283333, 51.533333), // Doha
        "RE": (-20.8789, 55.4481), // Saint-Denis
        "RO": (44.433333, 26.1), // Bucharest
        "RS": (44.833333, 20.5), // Belgrade
        "RU": (55.75, 37.583333), // Moscow
        "RW": (-1.95, 30.066667), // Kigali
        "SA": (24.633333, 46.716667), // Riyadh
        "SB": (-9.433333, 159.95), // Honiara
        "SC": (-4.633333, 55.45), // Victoria
        "SD": (15.6, 32.533333), // Khartoum
        "SE": (59.333333, 18.05), // Stockholm
        "SG": (1.283333, 103.85), // Singapore
        "SH": (-15.933333, -5.733333), // Jamestown
        "SI": (46.05, 14.516667), // Ljubljana
        "SJ": (78.216667, 15.55), // Longyearbyen
        "SK": (48.15, 17.116667), // Bratislava
        "SL": (8.5, -13.25), // Freetown
        "SM": (43.933333, 12.416667), // San Marino
        "SN": (14.666667, -17.433333), // Dakar
        "SO": (2.066667, 45.366667), // Mogadishu
        "SR": (5.833333, -55.166667), // Paramaribo
        "SS": (4.8594, 31.5713), // Juba
        "ST": (0.2, 6.65), // Sao Tome
        "SV": (13.7, -89.2), // San Salvador
        "SX": (18.026, -63.0458), // Philipsburg
        "SY": (33.5, 36.3), // Damascus
        "SZ": (-26.3, 31.1), // Mbabane
        "TC": (21.466667, -71.133333), // Grand Turk
        "TD": (12.1, 15.033333), // N'Djamena
        "TG": (6.133333, 1.216667), // Lome
        "TH": (13.75, 100.516667), // Bangkok
        "TJ": (38.583333, 68.8), // Dushanbe
        "TL": (-8.583333, 125.6), // Dili
        "TM": (37.95, 58.383333), // Ashgabat
        "TN": (36.8, 10.183333), // Tunis
        "TO": (-21.133333, -175.2), // Nuku'alofa
        "TR": (39.933333, 32.866667), // Ankara
        "TT": (10.65, -61.516667), // Port-of-Spain
        "TV": (-8.5, 179.2), // Funafuti
        "TW": (25.05, 121.5), // Taipei
        "TZ": (-6.163, 35.7516), // Dodoma
        "UA": (50.735, 30.923333), // Kiew
        "UG": (0.316667, 32.416667), // Kampala
        "US": (38.883333, -77.033333), // Washington, DC
        "UY": (-34.883333, -56.183333), // Montevideo
        "UZ": (41.333333, 69.3), // Tashkent
        "VA": (41.9, 12.45), // Vatican City
        "VC": (13.15, -61.233333), // Kingstown
        "VE": (10.5, -66.933333), // Caracas
        "VG": (18.45, -64.616667), // Road Town
        "VI": (18.35, -64.933333), // Charlotte Amalie
        "VN": (21.033333, 105.85), // Hanoi
        "VU": (-17.733333, 168.316667), // Port-Vila
        "WF": (-13.95, -171.933333), // Mata-Utu
        "WS": (-13.833333, -171.733333), // Apia
        "XK": (42.6629, 21.1655), // Pristina
        "YE": (15.35, 44.2), // Sanaa
        "YT": (-12.766667, 45.216667), // Mamoudzou
        "ZA": (-25.7, 28.216667), // Pretoria
        "ZM": (-15.416667, 28.283333), // Lusaka
        "ZW": (-17.833333, 31.05), // Harare
    ]
    private static let countryCodes: [String: String] = [
        "Andorra": "AD",
        "United Arab Emirates": "AE",
        "Afghanistan": "AF",
        "Antigua and Barbuda": "AG",
        "Anguilla": "AI",
        "Albania": "AL",
        "Armenia": "AM",
        "Angola": "AO",
        "Antarctica": "AQ",
        "Argentina": "AR",
        "American Samoa": "AS",
        "Austria": "AT",
        "Australia": "AU",
        "Aruba": "AW",
        "Åland Islands": "AX",
        "Azerbaijan": "AZ",
        "Bosnia and Herzegovina": "BA",
        "Barbados": "BB",
        "Bangladesh": "BD",
        "Belgium": "BE",
        "Burkina Faso": "BF",
        "Bulgaria": "BG",
        "Bahrain": "BH",
        "Burundi": "BI",
        "Benin": "BJ",
        "Saint Barthélemy": "BL",
        "Bermuda": "BM",
        "Brunei": "BN",
        "Bolivia": "BO",
        "Caribbean Netherlands": "BQ",
        "Brazil": "BR",
        "Bahamas": "BS",
        "Bhutan": "BT",
        "Bouvet Island": "BV",
        "Botswana": "BW",
        "Belarus": "BY",
        "Belize": "BZ",
        "Canada": "CA",
        "Cocos (Keeling) Islands": "CC",
        "DR Congo": "CD",
        "Central African Republic": "CF",
        "Congo": "CG",
        "Switzerland": "CH",
        "Ivory Coast": "CI",
        "Cook Islands": "CK",
        "Chile": "CL",
        "Cameroon": "CM",
        "China": "CN",
        "Colombia": "CO",
        "Costa Rica": "CR",
        "Cuba": "CU",
        "Cape Verde": "CV",
        "Curaçao": "CW",
        "Christmas Island": "CX",
        "Cyprus": "CY",
        "Czechia": "CZ",
        "Germany": "DE",
        "Djibouti": "DJ",
        "Denmark": "DK",
        "Dominica": "DM",
        "Dominican Republic": "DO",
        "Algeria": "DZ",
        "Ecuador": "EC",
        "Estonia": "EE",
        "Egypt": "EG",
        "Western Sahara": "EH",
        "Eritrea": "ER",
        "Spain": "ES",
        "Ethiopia": "ET",
        "Finland": "FI",
        "Fiji": "FJ",
        "Falkland Islands": "FK",
        "Micronesia": "FM",
        "Faroe Islands": "FO",
        "France": "FR",
        "Gabon": "GA",
        "United Kingdom": "GB",
        "Grenada": "GD",
        "Georgia": "GE",
        "French Guiana": "GF",
        "Guernsey": "GG",
        "Ghana": "GH",
        "Gibraltar": "GI",
        "Greenland": "GL",
        "Gambia": "GM",
        "Guinea": "GN",
        "Guadeloupe": "GP",
        "Equatorial Guinea": "GQ",
        "Greece": "GR",
        "South Georgia": "GS",
        "Guatemala": "GT",
        "Guam": "GU",
        "Guinea-Bissau": "GW",
        "Guyana": "GY",
        "Hong Kong": "HK",
        "Heard Island and McDonald Islands": "HM",
        "Honduras": "HN",
        "Croatia": "HR",
        "Haiti": "HT",
        "Hungary": "HU",
        "Indonesia": "ID",
        "Ireland": "IE",
        "Israel": "IL",
        "Isle of Man": "IM",
        "India": "IN",
        "British Indian Ocean Territory": "IO",
        "Iraq": "IQ",
        "Iran": "IR",
        "Iceland": "IS",
        "Italy": "IT",
        "Jersey": "JE",
        "Jamaica": "JM",
        "Jordan": "JO",
        "Japan": "JP",
        "Kenya": "KE",
        "Kyrgyzstan": "KG",
        "Cambodia": "KH",
        "Kiribati": "KI",
        "Comoros": "KM",
        "Saint Kitts and Nevis": "KN",
        "North Korea": "KP",
        "South Korea": "KR",
        "Kuwait": "KW",
        "Cayman Islands": "KY",
        "Kazakhstan": "KZ",
        "Laos": "LA",
        "Lebanon": "LB",
        "Saint Lucia": "LC",
        "Liechtenstein": "LI",
        "Sri Lanka": "LK",
        "Liberia": "LR",
        "Lesotho": "LS",
        "Lithuania": "LT",
        "Luxembourg": "LU",
        "Latvia": "LV",
        "Libya": "LY",
        "Morocco": "MA",
        "Monaco": "MC",
        "Moldova": "MD",
        "Montenegro": "ME",
        "Saint Martin": "MF",
        "Madagascar": "MG",
        "Marshall Islands": "MH",
        "North Macedonia": "MK",
        "Mali": "ML",
        "Myanmar": "MM",
        "Mongolia": "MN",
        "Macau": "MO",
        "Northern Mariana Islands": "MP",
        "Martinique": "MQ",
        "Mauritania": "MR",
        "Montserrat": "MS",
        "Malta": "MT",
        "Mauritius": "MU",
        "Maldives": "MV",
        "Malawi": "MW",
        "Mexico": "MX",
        "Malaysia": "MY",
        "Mozambique": "MZ",
        "Namibia": "NA",
        "New Caledonia": "NC",
        "Niger": "NE",
        "Norfolk Island": "NF",
        "Nigeria": "NG",
        "Nicaragua": "NI",
        "Netherlands": "NL",
        "Norway": "NO",
        "Nepal": "NP",
        "Nauru": "NR",
        "Niue": "NU",
        "New Zealand": "NZ",
        "Oman": "OM",
        "Panama": "PA",
        "Peru": "PE",
        "French Polynesia": "PF",
        "Papua New Guinea": "PG",
        "Philippines": "PH",
        "Pakistan": "PK",
        "Poland": "PL",
        "Saint Pierre and Miquelon": "PM",
        "Pitcairn Islands": "PN",
        "Puerto Rico": "PR",
        "Palestine": "PS",
        "Portugal": "PT",
        "Palau": "PW",
        "Paraguay": "PY",
        "Qatar": "QA",
        "Réunion": "RE",
        "Romania": "RO",
        "Serbia": "RS",
        "Russia": "RU",
        "Rwanda": "RW",
        "Saudi Arabia": "SA",
        "Solomon Islands": "SB",
        "Seychelles": "SC",
        "Sudan": "SD",
        "Sweden": "SE",
        "Singapore": "SG",
        "Saint Helena, Ascension and Tristan da Cunha": "SH",
        "Slovenia": "SI",
        "Svalbard and Jan Mayen": "SJ",
        "Slovakia": "SK",
        "Sierra Leone": "SL",
        "San Marino": "SM",
        "Senegal": "SN",
        "Somalia": "SO",
        "Suriname": "SR",
        "South Sudan": "SS",
        "São Tomé and Príncipe": "ST",
        "El Salvador": "SV",
        "Sint Maarten": "SX",
        "Syria": "SY",
        "Eswatini": "SZ",
        "Turks and Caicos Islands": "TC",
        "Chad": "TD",
        "French Southern and Antarctic Lands": "TF",
        "Togo": "TG",
        "Thailand": "TH",
        "Tajikistan": "TJ",
        "Tokelau": "TK",
        "Timor-Leste": "TL",
        "Turkmenistan": "TM",
        "Tunisia": "TN",
        "Tonga": "TO",
        "Türkiye": "TR",
        "Trinidad and Tobago": "TT",
        "Tuvalu": "TV",
        "Taiwan": "TW",
        "Tanzania": "TZ",
        "Ukraine": "UA",
        "Uganda": "UG",
        "United States Minor Outlying Islands": "UM",
        "United States": "US",
        "Uruguay": "UY",
        "Uzbekistan": "UZ",
        "Vatican City": "VA",
        "Saint Vincent and the Grenadines": "VC",
        "Venezuela": "VE",
        "British Virgin Islands": "VG",
        "United States Virgin Islands": "VI",
        "Vietnam": "VN",
        "Vanuatu": "VU",
        "Wallis and Futuna": "WF",
        "Samoa": "WS",
        "Kosovo": "XK",
        "Yemen": "YE",
        "Mayotte": "YT",
        "South Africa": "ZA",
        "Zambia": "ZM",
        "Zimbabwe": "ZW",
    ]
}
