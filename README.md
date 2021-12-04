# ElmFoodProject
Visualisierung von Nährwerten in Lebensmitteln
ELM-Projekt im Rahmen des Moduls "Information Retrieval und Visualisierung"

## Intro
Ziel des Projektes ist die Umsetzung von drei ausgewählten Visualisierungstechniken mithilfe der funktionalen Programmiersprache [Elm](https://elm-lang.org/). 
Die Visualisierung erfolgte basierend auf einem Datensatz verschiedener Lebensmittel und deren Nährwerte anhand der folgenden Visualisierungstechniken:
- Scatterplot
- Parallele Koordinaten
- Baumhierarchie

## Vorschau
#### Website ansehen
Die Visualisierungen sind als Website über folgenden Link abrufbar:

#### Repository herunterladen und lokal ansehen
1. Repository als .zip-Datei herunterladen und entpacken
2. Pakete installieren ([elm.json](elm.json) für benötigte Pakete ansehen)
3. Ordnerpfad über den Terminal aufrufen
4. Terminalbefehl `elm reactor` eingeben
5. `http://localhost:8000/` im Browser eingeben
6. Visualisierungen im Ordner `src/Develop` anschauen

## Datengrundlage
Der zugrunde liegende [Datensatz](https://www.kaggle.com/niharika41298/food-nutrition-analysis-eda) verschiedener Lebensmittel und deren Kalorien und Nährwerte wurde auf der Plattform bereitgestellt. Davon ausgehend wurden die Daten überarbeitet und unter [Daten](Daten) in [CSV](Daten/CSV) und [JSON](Daten/JSON) bereitgestellt.

## Pakete
- [alex-tan/elm-tree-diagram (Version: 1.0.0)](https://package.elm-lang.org/packages/alex-tan/elm-tree-diagram/1.0.0)
- [avh4/elm-color (Version: 1.0.0)](https://package.elm-lang.org/packages/avh4/elm-color/1.0.0)
- [elm/browser (Version: 1.0.2)](https://package.elm-lang.org/packages/elm/browser/1.0.2)
- [elm/core (Version: 1.0.5)](https://package.elm-lang.org/packages/elm/core/1.0.5)
- [elm/html (Version: 1.0.0)](https://package.elm-lang.org/packages/elm/html/1.0.0)
- [elm/http (Version: 2.0.0)](https://package.elm-lang.org/packages/elm/http/2.0.0)
- [elm/json (Version: 1.1.3)](https://package.elm-lang.org/packages/elm/json/1.1.3)
- [elm-community/list-extra (Version: 8.3.1)](https://package.elm-lang.org/packages/elm-community/list-extra/8.3.1)
- [elm-community/typed-svg (Version: 7.0.0)](https://package.elm-lang.org/packages/elm-community/typed-svg/7.0.0)
- [ericgj/elm-csv-decode (Version: 2.0.1)](https://package.elm-lang.org/packages/ericgj/elm-csv-decode/2.0.1)
- [folkertdev/one-true-path-experiment (Version: 6.0.0)](https://package.elm-lang.org/packages/folkertdev/one-true-path-experiment/6.0.0)
- [gampleman/elm-visualization (Version 2.3.0)](https://package.elm-lang.org/packages/gampleman/elm-visualization/2.3.0)
- [lovasoa/elm-csv (Version: 1.1.7)](https://package.elm-lang.org/packages/lovasoa/elm-csv/1.1.7)
- [zwilias/elm-reorderable (Version: 1.3.0)](https://package.elm-lang.org/packages/zwilias/elm-reorderable/1.3.0)