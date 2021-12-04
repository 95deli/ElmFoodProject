module Devlop.ELMScatterplot exposing (..)

import Axis
import Html exposing (Html)
import Http
import Scale exposing (ContinuousScale)
import Statistics
import TypedSvg exposing (circle, g, style, svg, text_)
import TypedSvg.Attributes exposing (class, fontFamily, fontSize, textAnchor, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (cx, cy, r, x, y)
import TypedSvg.Core exposing (Svg)
import TypedSvg.Types exposing (AnchorAlignment(..), FontWeight(..), Length(..), Transform(..), px)
import Csv
import Csv.Decode
import Browser
import Html exposing (ul)
import Html exposing (li)
import Html.Events exposing (onClick)

type Model
  = Error
  | Loading
  | Success 
    { data : List Nutrients
    , xFunction : Nutrients -> Float
    , yFunction : Nutrients -> Float
    , xName : String
    , yName : String
    }

type Msg
    = GotText (Result Http.Error String)
    | ChangeX (Nutrients -> Float, String)
    | ChangeY (Nutrients -> Float, String)

type alias Nutrients =
    { name : String
    , proteins : Float
    , fat : Float
    , satfat : Float
    , fiber : Float
    , carbs : Float
    }

type alias Point =
    { pointName : String, x : Float, y : Float }

type alias XYData =
    { xDescription : String
    , yDescription : String
    , data : List Point
    }

getCsv : (Result Http.Error String -> Msg) -> Cmd Msg
getCsv x = 
    list
        |> List.map
            (\data ->
                Http.get
                    { url = "https://raw.githubusercontent.com/95deli/ElmFoodProject/main/Daten/CSV/" ++ data
                    , expect = Http.expectString x
                    }
            )
        |> Cmd.batch

list : List String
list =
    [ "NutrientsFINAL.csv"]

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
            |> Csv.Decode.andMap (Csv.Decode.field "proteins"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "fat"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "satfat"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "fiber"(String.toFloat >> Result.fromMaybe "error parsing string"))
            |> Csv.Decode.andMap (Csv.Decode.field "carbs"(String.toFloat >> Result.fromMaybe "error parsing string"))
        )

nutrientsList :List String -> List Nutrients
nutrientsList list1 =
    List.map(\t -> csvStringToData t) list1
        |> List.concat
        
filterReducedNutrients : List Nutrients -> (Nutrients -> String) -> (Nutrients -> Float) -> (Nutrients -> Float) -> String -> String -> XYData
filterReducedNutrients nutrientsliste a b c x y =
    XYData x y (List.map (\n -> pointName n a b c x y) nutrientsliste)

w : Float
w =
    900

h : Float
h =
    450

padding : Float
padding =
    60


radius : Float
radius =
    5.0

-- Axis section

tickCount : Int
tickCount =
    5

xAxis : List Float -> Svg msg
xAxis values =
    Axis.bottom [ Axis.tickCount tickCount ] (xScale values)


yAxis : List Float -> Svg msg
yAxis values =
    Axis.left [ Axis.tickCount tickCount ] (yScale values)

xScale : List Float -> ContinuousScale Float
xScale values =
    Scale.linear ( 0, w - 2 * padding ) ( wideExtent values )

yScale : List Float -> ContinuousScale Float
yScale values =
    Scale.linear ( h - 2 * padding, 0 ) ( wideExtent values )

defaultExtent : ( number, number1 )
defaultExtent =
    ( 0, 100 )

adding : (Float, Float) -> Float-> (Float, Float) 
adding (min, max) x =
    if min <= 0 then
        ( 0, max + x)
    else 
        (min - x, max + x)

wideExtent : List Float -> ( Float, Float )
wideExtent values = 
    let
        result = 
            Maybe.withDefault (0, 0)
            (Statistics.extent values)
        
        max =          
            Maybe.withDefault (0)
            (List.maximum values)
            
        result1 = 
            adding result (toFloat(tickCount)*max/50)
        
        result2 = 
            adding result1 (0.0)       
    in
        result2

-- Point name settings

pointName : Nutrients -> (Nutrients -> String) -> (Nutrients -> Float) -> (Nutrients -> Float) -> String -> String -> Point
pointName nutrients u v x y z =
    Point (u nutrients ++ ", " ++ y ++ ": " ++ String.fromFloat (v nutrients) ++ ", " ++ z ++ ": " ++ String.fromFloat (x nutrients)) (v nutrients) (x nutrients)

point : ContinuousScale Float -> ContinuousScale Float -> Point -> Svg msg
point scaleX scaleY yxPoint =
    g
        [
            class["point"]
            ,fontSize <| Px 12.0
            ,fontFamily ["calibri"]
            ,transform
                [
                    Translate
                    (Scale.convert scaleX yxPoint.x)
                    (Scale.convert scaleY yxPoint.y)
                ]
        ]

        [
            circle [cx 0, cy 0, r 5] []
            , text_ [x 10, y -20, textAnchor AnchorMiddle] [Html.text yxPoint.pointName]
        ]

scatterplot : XYData -> Svg msg
scatterplot model =
    let
        xValues : List Float
        xValues =
            List.map .x model.data

        yValues : List Float
        yValues =
            List.map .y model.data

        xScaleLocal : ContinuousScale Float
        xScaleLocal =
            xScale xValues

        yScaleLocal : ContinuousScale Float
        yScaleLocal =
            yScale yValues

        half : ( Float, Float ) -> Float
        half t =
            (Tuple.second t - Tuple.first t) / 2

        labelPosition : { x : Float, y : Float }
        labelPosition =
            { x = wideExtent xValues |> half
            , y = wideExtent yValues |> Tuple.second
            }
    in
    svg [ viewBox 0 0 w h, TypedSvg.Attributes.width <| TypedSvg.Types.Percent 100, TypedSvg.Attributes.height <| TypedSvg.Types.Percent 100 ]
        [ style [] [ TypedSvg.Core.text """
            .point circle { stroke: rgba(0, 0, 0,0.4); fill: rgba(255, 255, 255,0.3); }
            .point text { display: none; }
            .point:hover circle { stroke: rgba(0, 0, 0,1.0); fill: rgb(118, 214, 78); }
            .point:hover text { display: inline; }
          """ ]
        , g [ transform [ Translate 60 390 ] ]
            [ xAxis xValues
            , text_
                [ x (Scale.convert xScaleLocal labelPosition.x)
                , y 35
                 , fontFamily [ "calibri" ]
                , fontSize (px 20)
                ]
                [ TypedSvg.Core.text model.xDescription ]
            ]
        , g [ transform [ Translate 60 60 ] ]
            [ yAxis yValues
            , text_
                [ x -30
                , y -30
                , fontFamily [ "calibri" ]
                , fontSize (px 20)
                ]
                [ TypedSvg.Core.text model.yDescription ]
            ]
        , g [ transform [ Translate padding padding ] ]
            (List.map (point xScaleLocal yScaleLocal) model.data)
        ]

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
                nutrients =
                    filterReducedNutrients l.data .name l.xFunction l.yFunction l.xName l.yName

            in
            Html.div []
                [
                    ul[][
                        li[][
                            Html.text <| "Please choose a nutrient type for the x-axis. "
                            , Html.button [onClick (ChangeX (.proteins, "Proteins"))][Html.text "Proteins"]
                            , Html.button [onClick (ChangeX (.fat, "Fat"))][Html.text "Fat"]
                            , Html.button [onClick (ChangeX (.satfat, "Saturated Fat"))][Html.text "Saturated Fat"]
                            , Html.button [onClick (ChangeX (.fiber, "Fiber"))][Html.text "Fiber"]
                            , Html.button [onClick (ChangeX (.carbs, "Carbohydrates"))][Html.text "Carbohydrates"]
                        ]
                    ]
                    , ul[][
                        li[][
                            Html.text <| "Please choose a nutrient type for the y-axis. "
                            , Html.button [onClick (ChangeY (.proteins, "Proteins"))][Html.text "Proteins"]
                            , Html.button [onClick (ChangeY (.fat, "Fat"))][Html.text "Fat"]
                            , Html.button [onClick (ChangeY (.satfat, "Saturated Fat"))][Html.text "Saturated Fat"]
                            , Html.button [onClick (ChangeY (.fiber, "Fiber"))][Html.text "Fiber"]
                            , Html.button [onClick (ChangeY (.carbs, "Carbohydrates"))][Html.text "Carbohydrates"]
                        ]
                    ] 
                    ,   scatterplot nutrients
                ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText result ->
            case result of
                Ok fullText ->
                    ( Success <| { data = nutrientsList [ fullText ], xFunction = .carbs, yFunction = .proteins , xName = "Carbohydrates", yName = "Proteins"}, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )
        ChangeX (x, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, xFunction = x, yFunction = m.yFunction, xName = a, yName = m.yName }, Cmd.none )

                _ ->
                    ( model, Cmd.none )
        ChangeY (y, a) ->
            case model of
                Success m ->
                    ( Success <| { data = m.data, xFunction = m.xFunction, yFunction = y, xName = m.xName, yName = a }, Cmd.none )

                _ ->
                    ( model, Cmd.none )