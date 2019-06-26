port module Elmstatic exposing
    ( Content
    , Layout
    , Page
    , Post
    , decodePage
    , htmlTemplate
    , inlineScript
    , layout
    , script
    , stylesheet
    )

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import PageType exposing (PostData, PostList, postDataDecoder)
import SiteConfig exposing (SiteConfig)


type alias Post =
    PostData


type alias Page =
    { markdown : String
    , siteTitle : String
    , title : String
    }


type alias Content a =
    { a | title : String }


type alias SiteContent a =
    { siteConfig : SiteConfig
    , content : Content a
    }


type alias Layout =
    Program Decode.Value Decode.Value Never


decodePage : Decode.Decoder Page
decodePage =
    Decode.map3 Page
        (Decode.field "markdown" Decode.string)
        (Decode.field "siteTitle" Decode.string)
        (Decode.field "title" Decode.string)


script : String -> Html Never
script src =
    node "citatsmle-script" [ attribute "src" src ] []


inlineScript : String -> Html Never
inlineScript js =
    node "citatsmle-script" [] [ text js ]


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
            , script "//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.1/highlight.min.js"
            , script "//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.1/languages/elm.min.js"
            , inlineScript "hljs.initHighlightingOnLoad();"
            , stylesheet "//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.15.1/styles/default.min.css"
            , stylesheet "//fonts.googleapis.com/css?family=Open+Sans|Proza+Libre|Inconsolata"
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
                        , body = [ htmlTemplate "Error" [ Html.text <| Decode.errorToString error ] ]
                        }

                    Ok input ->
                        { title = ""
                        , body = [ htmlTemplate input.siteConfig.title <| view input.content ]
                        }
        , update = \msg contentJson -> ( contentJson, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


sendError : String -> Cmd msg
sendError errMsg =
    renderError (Encode.string errMsg)


port renderError : Encode.Value -> Cmd msg
