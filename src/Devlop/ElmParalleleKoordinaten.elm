module Devlop.ElmParalleleKoordinaten exposing (..)

import Axis
import Browser
import Color
import Csv
import Csv.Decode
import Html exposing (Html, a, li, ul)
import Html.Events exposing (onClick)
import Http
import List.Extra
import Path
import Scale exposing (ContinuousScale)
import Shape
import Statistics
import TypedSvg exposing (g, svg, text_)
import TypedSvg.Attributes exposing (d, fill, fontFamily, fontSize, stroke, strokeWidth, textAnchor, transform, viewBox, class)
import TypedSvg.Attributes.InPx exposing (x, y)
import TypedSvg.Core exposing (Svg)
import TypedSvg.Types exposing (AnchorAlignment(..), Length(..), Paint(..), Transform(..))

type Model
  = Error
  | Loading
  | Success 
    { data : List Nutrients
    , firstFunction : Nutrients -> Float
    , secondFunction : Nutrients -> Float
    , thirdFunction : Nutrients -> Float
    , fourthFunction : Nutrients -> Float
    , firstName : String
    , secondName : String
    , thirdName : String
    , fourthName : String
    }

type alias Nutrients =
    { name : String
    , calories : Float
    , proteins : Float
    , fat : Float
    , satfat : Float
    , fiber : Float
    , carbs : Float
    }

type Msg
    = GotText (Result Http.Error String)
    | Change1 (Nutrients -> Float, String)
    | Change2 (Nutrients -> Float, String)
    | Change3 (Nutrients -> Float, String)
    | Change4 (Nutrients -> Float, String)

type alias MultiDimPoint =
    { pointName : String, value : List Float }

type alias MultiDimData =
    { dimDescription : List String
    , data : List (List MultiDimPoint)
    }

getCsv : (Result Http.Error String -> Msg) -> Cmd Msg
getCsv x = 
    list
        |> List.map
            (\data ->
                Http.get
                    { url = "https://raw.githubusercontent.com/95deli/ElmFoodProject/main/Data/CSV" ++ data
                    , expect = Http.expectString x
                    }
            )
        |> Cmd.batch

list : List String
list =
    [ "nutrients.csv"]

csvStringToData : String -> List Nutrients
csvStringToData csvRaw =
    Csv.parse csvRaw
        |> Csv.Decode.decodeCsv decodingNutrients
        |> Result.toMaybe
        |> Maybe.withDefault []

decodingNutrients : Csv.Decode.Decoder (Nutrients -> a) a
decodingNutrients =
    Csv.Decode.map Nutrients
        (Csv.Decode.field "name" Ok
            |> Csv.Decode.andMap (Csv.Decode.field "calories"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "proteins"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "fat"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "satfat"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "fiber"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "carbs"(String.toFloat >> Result.fromMaybe "error parsing string"))
        )

nutrientsList :List String -> List Nutrients
nutrientsList list1 =
    List.map(\t -> csvStringToData t) list
        |> List.concat

padding : Float
padding =
    60

radius : Float
radius =
    5.0

tickCount : Int
tickCount =
    8

defaultExtent : ( number, number1 )
defaultExtent =
    ( 0, 100 )

wideExtent : List Float -> ( Float, Float )
wideExtent values =
    let
        closeExtent =
            Statistics.extent values
                |> Maybe.withDefault defaultExtent

        extent =
            (Tuple.second closeExtent - Tuple.first closeExtent) / toFloat (2 * tickCount)
    in
    ( Tuple.first closeExtent - extent |> max 0
    , Tuple.second closeExtent + extent
    )

parallelCoordinatesPlot : Float -> Float -> MultiDimData -> Svg msg
parallelCoordinatesPlot w ar model =
    let
        h : Float
        h =
            w / ar

        listTransformieren : List (List Float)
        listTransformieren =
            model.data
                |> List.concat
                |> List.map .value
                |> List.Extra.transpose

        listWideExtent : List ( Float, Float )
        listWideExtent =
            listTransformieren |> List.map wideExtent

        listScale =
            List.map (Scale.linear ( h, 0 )) listWideExtent

        listAxis =
            List.map (Axis.left [ Axis.tickCount tickCount ]) listScale

        xScale =
            Scale.linear ( 0, w ) ( 1, List.length model.dimDescription |> toFloat )
    in
    svg
        [ viewBox 0 0 (w + 2 * padding) (h + 2 * padding)
        , TypedSvg.Attributes.width <| TypedSvg.Types.Percent 90
        , TypedSvg.Attributes.height <| TypedSvg.Types.Percent 90
        ]
    <|
        [ TypedSvg.style []
            [
                TypedSvg.Core.text """
                .parallelPoint { stroke: rgba(1, 0, 0,0.2);}
                .parallelPoint:hover {stroke: rgb(173, 255, 47); stroke-width: 2;} 
                .parallelPoint text { display: none; }
                .parallelPoint:hover text { display: inline; stroke: rgb(0, 0, 0); stroke-width: 0.1; font-size: small; font-family: calibri}  
                """
            ]
        , g [ TypedSvg.Attributes.class [ "parallelAxis" ] ]
            [ g [ transform [ Translate (padding - 1) padding ] ] <|
                List.indexedMap
                    (\i axis ->
                        g
                            [ transform
                                [ Translate (Scale.convert xScale (toFloat i + 1)) 0
                                ]
                            ]
                            [ axis ]
                    )
                    listAxis
            , g [ transform [ Translate (padding - 1) 0 ] ] <|
                List.indexedMap
                    (\i desc ->
                        text_
                            [ fontFamily [ "calibri" ]
                            , fontSize (Px 12)
                            , x <| Scale.convert xScale (toFloat i + 1)
                            , y <| padding * 7 / 8
                            , textAnchor AnchorMiddle
                            ]
                            [ TypedSvg.Core.text desc ]
                    )
                    model.dimDescription
            ]
        ]
            ++ (let
                    drawPoint p name description =
                        let
                            linePath : Path.Path
                            linePath =
                                List.map3
                                    (\desc s px ->
                                        Just
                                            ( Scale.convert xScale <| toFloat desc
                                            , Scale.convert s px
                                            )
                                    )
                                    (List.range 1 (List.length model.dimDescription))
                                    listScale
                                    p
                                    |> Shape.line Shape.linearCurve
                        in
                        g [class ["parallelPoint"]][
                            Path.element linePath
                            [ stroke <| Paint <| Color.rgba 0 0 0 0.8
                            , strokeWidth <| Px 0.5
                            , fill PaintNone
                            , class ["parallelPoint"]
                            ]
                            , text_
                                [ x 300
                                , y -20
                                , TypedSvg.Attributes.textAnchor AnchorMiddle
                                ]
                                [ TypedSvg.Core.text (name++ (String.concat<|(List.map2(\a b-> ", " ++b++ ": "++ (String.fromFloat a))p description)))]
                                
                        ]
                        
                in
                model.data
                    |> List.map
                        (\dataset ->
                            g [ transform [ Translate (padding - 1) padding ] ]
                                (List.map (\a -> drawPoint a.value a.pointName model.dimDescription) dataset)
                        )
               )
main =
  Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }

init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , getCsv GotText
    )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

view : Model -> Html Msg
view model =
    case model of
        Error ->
            Html.text "Sorry, I could not open nutrients data."

        Loading ->
            Html.text "Loading nutrients..."

        Success l ->
                    let
                        multiDimDaten : List Nutrients -> (Nutrients -> Float) -> (Nutrients -> Float) -> (Nutrients -> Float) -> (Nutrients -> Float) -> (Nutrients -> String) -> String -> String -> String -> String-> MultiDimData
                        multiDimDaten listNutrients a b c d e f g h i=
                         MultiDimData [f, g, h, i]
                            [ List.map
                                (\x ->
                                    [(a x), (b x), (c x), (d x)]
                                        |> MultiDimPoint (e x)
                                )
                                listNutrients
                            ]

                        plotData = 
                            multiDimDaten l.data l.firstFunction l.secondFunction l.thirdFunction l.fourthFunction .name l.firstName l.secondName l.thirdName l.fourthName       
                    in
                    Html.div []
                        [
                            ul[][
                                li[][
                                    Html.text <| "Please choose a nutrient type for the first column."
                                    , Html.button [onClick (Change1 (.calories, "calories"))][Html.text "Calories"]
                                    , Html.button [onClick (Change1 (.proteins, "proteins"))][Html.text "Proteins"]
                                    , Html.button [onClick (Change1 (.fat, "fat"))][Html.text "Fat"]
                                    , Html.button [onClick (Change1 (.satfat, "satfat"))][Html.text "Saturated Fat"]
                                    , Html.button [onClick (Change1 (.fiber, "fiber"))][Html.text "Fiber"]
                                    , Html.button [onClick (Change1 (.carbs, "carbs"))][Html.text "Carbohydrates"]
                                ]
                            ]
                            , ul[][
                                li[][
                                    Html.text <| "Please choose a nutrient type for the second column."
                                    , Html.button [onClick (Change1 (.calories, "calories"))][Html.text "Calories"]
                                    , Html.button [onClick (Change1 (.proteins, "proteins"))][Html.text "Proteins"]
                                    , Html.button [onClick (Change1 (.fat, "fat"))][Html.text "Fat"]
                                    , Html.button [onClick (Change1 (.satfat, "satfat"))][Html.text "Saturated Fat"]
                                    , Html.button [onClick (Change1 (.fiber, "fiber"))][Html.text "Fiber"]
                                    , Html.button [onClick (Change1 (.carbs, "carbs"))][Html.text "Carbohydrates"]
                                ]
                            ]
                            , ul[][
                                li[][
                                    Html.text <| "Please choose a nutrient type for the third column."
                                    , Html.button [onClick (Change1 (.calories, "calories"))][Html.text "Calories"]
                                    , Html.button [onClick (Change1 (.proteins, "proteins"))][Html.text "Proteins"]
                                    , Html.button [onClick (Change1 (.fat, "fat"))][Html.text "Fat"]
                                    , Html.button [onClick (Change1 (.satfat, "satfat"))][Html.text "Saturated Fat"]
                                    , Html.button [onClick (Change1 (.fiber, "fiber"))][Html.text "Fiber"]
                                    , Html.button [onClick (Change1 (.carbs, "carbs"))][Html.text "Carbohydrates"]
                                ]
                            ]
                            , ul[][
                                li[][
                                    Html.text <| "Please choose a nutrient type for the fourth column."
                                    , Html.button [onClick (Change1 (.calories, "calories"))][Html.text "Calories"]
                                    , Html.button [onClick (Change1 (.proteins, "proteins"))][Html.text "Proteins"]
                                    , Html.button [onClick (Change1 (.fat, "fat"))][Html.text "Fat"]
                                    , Html.button [onClick (Change1 (.satfat, "satfat"))][Html.text "Saturated Fat"]
                                    , Html.button [onClick (Change1 (.fiber, "fiber"))][Html.text "Fiber"]
                                    , Html.button [onClick (Change1 (.carbs, "carbs"))][Html.text "Carbohydrates"]
                                ]
                             ]
                                ,parallelCoordinatesPlot 600 2 plotData
                        ]
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            case result of
                Ok fullText ->
                    ( Success <| { data = nutrientsList [ fullText ], firstFunction = .calories, secondFunction = .proteins, thirdFunction = .fat, fourthFunction = .satfat , firstName = "Calories", secondName = "Proteins", thirdName = "Fat", fourthName = "Saturated Fat"}, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )
        Change1 (x, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, firstFunction = x, secondFunction = m.secondFunction, thirdFunction = m.thirdFunction, fourthFunction = m.fourthFunction , firstName = a, secondName = m.secondName, thirdName = m.thirdName, fourthName = m.fourthName}, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        Change2 (y, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, firstFunction = m.firstFunction, secondFunction = y, thirdFunction = m.thirdFunction, fourthFunction = m.fourthFunction , firstName = m.firstName, secondName = a, thirdName = m.thirdName, fourthName = m.fourthName}, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        Change3 (z, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, firstFunction = m.firstFunction, secondFunction = m.secondFunction, thirdFunction = z, fourthFunction = m.fourthFunction , firstName = m.firstName, secondName = m.secondName, thirdName = a, fourthName = m.fourthName}, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        Change4 (c, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, firstFunction = m.firstFunction, secondFunction = m.secondFunction, thirdFunction = m.thirdFunction, fourthFunction = c , firstName = m.firstName, secondName = m.secondName, thirdName = m.thirdName, fourthName = a}, Cmd.none )

                _ ->
                    ( model, Cmd.none )