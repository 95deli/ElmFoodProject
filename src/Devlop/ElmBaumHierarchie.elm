module Devlop.ElmBaumhierarchie exposing (..)

import Browser
import Color
import Html exposing (Html, div, text)
import Http
import Json.Decode
import TreeDiagram
import TreeDiagram.Svg
import TypedSvg exposing (circle, g, line, text_)
import TypedSvg.Attributes exposing (fill, stroke, textAnchor, transform, fontFamily, fontSize)
import TypedSvg.Attributes.InPx exposing (cx, cy, r, x1, x2, y1, y2)
import TypedSvg.Core exposing (Svg)
import TypedSvg.Types as ST exposing (AnchorAlignment(..), Length(..), Paint(..), Transform(..))
import TreeDiagram exposing (TreeLayout, topToBottom)

type Msg
    = GotTree (Result Http.Error (TreeDiagram.Tree String))

type alias Model =
    { tree : TreeDiagram.Tree String, errorMsg : String }

-- type alias TreeLayout =
--     { orientation : TreeOrientation
--     , subtreeDistance : Int
--     , siblingDistance : Int
--     , padding : Int
--    }

treeLayout : TreeLayout
treeLayout =
    TreeLayout topToBottom
            250
            45
            300
            300

drawLine : ( Float, Float ) -> Svg msg
drawLine ( targetX, targetY ) =
    line
        [ x1 0
        , y1 0
        , x2 targetX
        , y2 targetY
        , stroke (ST.Paint Color.darkGray)
        ]
        []

drawNode : String -> Svg msg
drawNode n =
    g
        []
        [ circle 
            [ r 14
                , stroke (Paint Color.darkGray)
                , fill (Paint Color.lightGreen)
                , cx 0
                , cy 0 
            ] 
            []
        , text_ 
            [ textAnchor AnchorEnd
                , transform 
                    [  Translate -5.5 -20.5 
                     , Rotate 50.0 0.0 0.0
                    ]
            , fontFamily [ "calibri" ]
            , fontSize (Px 14)
            ] 
            [ text n ]
        ]

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : () -> ( Model, Cmd Msg )
init () =
    ( { tree = TreeDiagram.node "" [], errorMsg = "Loading ..." }
    , Http.get { url = "https://raw.githubusercontent.com/95deli/ElmFoodProject/main/Daten/JSON/BaumhierarchieJSON.json"
    , expect = Http.expectJson GotTree jsonDecoding }
    )

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTree (Ok newTree) ->
            ( { model | tree = newTree, errorMsg = "No Error" }, Cmd.none )

        GotTree (Err error) ->
            ( { model
                | tree = TreeDiagram.node "" []
                , errorMsg =
                    case error of
                        Http.BadBody newErrorMsg ->
                            newErrorMsg

                        _ ->
                            "Some other Error"
              }
            , Cmd.none
            )

view : Model -> Html Msg
view model =
    div []
        [ TreeDiagram.Svg.draw treeLayout drawNode drawLine model.tree
        ]

jsonDecoding : Json.Decode.Decoder (TreeDiagram.Tree String)
jsonDecoding =
    Json.Decode.map2
        (\name children ->
            case children of
                Nothing ->
                    TreeDiagram.node name []

                Just c ->
                    TreeDiagram.node name c
        )
        (Json.Decode.field "data" (Json.Decode.field "id" Json.Decode.string))
        (Json.Decode.maybe <|
            Json.Decode.field "children" <|
                Json.Decode.list <|
                    Json.Decode.lazy
                        (\_ -> jsonDecoding)
        )