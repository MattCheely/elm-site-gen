module Post exposing (main, metadataHtml)

import Elmstatic exposing (..)
import Html exposing (..)
import Html.Attributes as Attr exposing (alt, attribute, class, href, src)
import Json.Decode as Decode exposing (Decoder)
import Page
import PageType exposing (PostData, postDataDecoder)


tagsToHtml : List String -> List (Html Never)
tagsToHtml tags =
    let
        tagLink tag =
            "/tags/" ++ String.toLower tag

        linkify tag =
            a [ href <| tagLink tag ] [ text tag ]
    in
    List.map linkify tags


metadataHtml : PostData -> Html Never
metadataHtml post =
    div [ class "post-metadata" ]
        ([ span [] [ text post.date ]
         , span [] [ text "•" ]
         ]
            ++ tagsToHtml post.tags
        )


main : Elmstatic.Layout
main =
    Elmstatic.layout postDataDecoder <|
        \post ->
            Page.layout
                post.title
                [ metadataHtml post, Page.markdown post.content ]
