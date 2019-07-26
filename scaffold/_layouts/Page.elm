module Page exposing (layout, main, markdown)

import Accessibility.Styled as Html exposing (..)
import Content exposing (pageDataDecoder)
import Elmstatic exposing (..)
import Html.Styled.Attributes as Attr exposing (alt, attribute, class, href, src, tabindex)
import Markdown
import Styles


burgerIcon : Html Never
burgerIcon =
    div [ class "menuIcon", tabindex -1 ]
        [ div [ class "burgerAlt" ] []
        , div [ class "burger" ] []
        , div [ class "burgerAlt" ] []
        , div [ class "burger" ] []
        , div [ class "burgerAlt" ] []
        , div [ class "burger" ] []
        ]


menu : Html Never
menu =
    nav [ class "menu" ]
        [ burgerIcon
        , ul [ class "menu-items" ]
            [ li [] [ a [ href "/" ] [ text "Home" ] ]
            , li [] [ a [ href "/about/" ] [ text "About" ] ]
            , li [] [ a [ href "/contact/" ] [ text "Contact" ] ]
            ]
        ]


markdown : String -> Html Never
markdown mdString =
    let
        mdOptions : Markdown.Options
        mdOptions =
            { defaultHighlighting = Just "elm"
            , githubFlavored = Just { tables = False, breaks = False }
            , sanitize = False
            , smartypants = True
            }
    in
    Markdown.toHtmlWith mdOptions [] mdString
        |> Html.fromUnstyled


layout : String -> List (Html Never) -> List (Html Never)
layout title contentItems =
    [ menu
    , div [ class "content" ]
        ([ h1 [] [ text title ] ] ++ contentItems)
    , Styles.styles
        |> Html.fromUnstyled
    ]


main : Elmstatic.Layout
main =
    Elmstatic.layout pageDataDecoder <|
        \page ->
            layout page.title [ markdown page.content ]
