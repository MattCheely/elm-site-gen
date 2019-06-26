module Posts exposing (main)

import Elmstatic
import Html exposing (..)
import Html.Attributes as Attr exposing (alt, attribute, class, href, src)
import Page
import PageType exposing (PostData)
import Post


main : Elmstatic.Layout
main =
    let
        postListContent posts =
            if List.isEmpty posts then
                [ text "No posts yet!" ]

            else
                List.map postItemView posts

        sortPosts posts =
            List.sortBy .date posts
                |> List.reverse
    in
    Elmstatic.layout PageType.postListDecoder <|
        \content ->
            Page.layout content.title <| postListContent <| sortPosts content.posts


postItemView : PostData -> Html Never
postItemView post =
    div []
        [ a [ href ("/" ++ PageType.postPath post) ] [ h2 [] [ text post.title ] ]
        , Post.metadataHtml post
        ]
