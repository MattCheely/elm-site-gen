port module Elmstatic exposing
    ( Content
    , Layout
    , htmlTemplate
    , layout
    , stylesheet
    )

import Accessibility.Styled as Html exposing (..)
import Browser
import Content exposing (PageData, PostData, PostList, postDataDecoder)
import Html.Styled exposing (node)
import Html.Styled.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import SiteConfig exposing (SiteConfig)


type alias Content a =
    { a | title : String }


type alias SiteContent a =
    { siteConfig : SiteConfig
    , content : Content a
    }


type alias Layout =
    Program Decode.Value Decode.Value Never


stylesheet : String -> Html Never
stylesheet href =
    node "link" [ attribute "href" href, attribute "rel" "stylesheet", attribute "type" "text/css" ] []


htmlTemplate : String -> List (Html Never) -> Html Never
htmlTemplate title contentNodes =
    node "html"
        []
        [ node "head"
            []
            [ node "title" [] [ text title ]
            , node "meta" [ attribute "charset" "utf-8" ] []
            , stylesheet "//fonts.googleapis.com/css?family=Alegreya|Space+Mono&display=swap"
            , stylesheet "//indestructibletype.com/fonts/Jost.css"
            ]
        , node "body" [] contentNodes
        ]


layout : Decoder (Content content) -> (Content content -> List (Html Never)) -> Layout
layout contentDecoder view =
    let
        decoder =
            Decode.map2 SiteContent
                (Decode.field "siteConfig" SiteConfig.decoder)
                (Decode.at [ "content", "data" ] contentDecoder)
    in
    Browser.document
        { init =
            \contentJson ->
                case Decode.decodeValue decoder contentJson of
                    Ok _ ->
                        ( contentJson, Cmd.none )

                    Err error ->
                        ( contentJson, sendError (Decode.errorToString error) )
        , view =
            \contentJson ->
                case Decode.decodeValue decoder contentJson of
                    Err error ->
                        { title = ""
                        , body =
                            [ htmlTemplate "Error" [ Html.text <| Decode.errorToString error ]
                                |> Html.toUnstyled
                            ]
                        }

                    Ok input ->
                        { title = ""
                        , body =
                            [ htmlTemplate input.content.title (view input.content)
                                |> Html.toUnstyled
                            ]
                        }
        , update = \msg contentJson -> ( contentJson, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


sendError : String -> Cmd msg
sendError errMsg =
    renderError (Encode.string errMsg)


port renderError : Encode.Value -> Cmd msg
