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

type alias MultiDimPunkt =
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
                    { url = "" ++ data
                    , expect = Http.expectString x
                    }
            )
        |> Cmd.batch

list : List String
list =
    [ ""]

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

distance : Float
distance =
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