module Styles exposing (colors, styles)

import Css exposing (..)
import Css.Global exposing (..)
import Css.Media as Media exposing (..)
import Html exposing (Html)
import Html.Styled


type alias Colors =
    { backgroundPrimary : String
    , backgroundSecondary : String
    , fontPrimary : String
    , border : String
    , link : String
    }


type alias Fonts =
    { headerFamily : String
    , bodyFamily : String
    }


fonts =
    Fonts "Jost" "Alegreya"


colors =
    Colors
        "fef8f4"
        "d5d4c2"
        "3b413b"
        "b4b3b1"
        "676d71"


typography =
    [ body
        [ fontFamilies [ fonts.bodyFamily, .value serif ]
        , fontSize <| Css.rem 1.5
        ]
    , h1
        [ fontSize <| Css.em 2.66667
        , marginBottom <| rem 2.0202
        ]
    , h2
        [ fontSize <| Css.em 2.0
        , marginBottom <| rem 1.61616
        ]
    , h3
        [ fontSize <| Css.em 1.33333
        , marginBottom <| rem 1.21212
        ]
    , h4
        [ fontSize <| Css.em 1.2
        , marginBottom <| rem 0.80808
        ]
    , each [ h5, h6 ]
        [ fontSize <| Css.em 1.0
        , marginBottom <| rem 0.60606
        ]
    , each [ h1, h2, h3, h4, h5, h6 ]
        [ fontFamilies [ fonts.headerFamily, .value sansSerif ]
        , lineHeight <| Css.em 1
        , marginTop <| px 0
        ]
    , class "menu"
        [ fontFamilies [ fonts.headerFamily, .value sansSerif ] ]
    ]


theme =
    let
        activeMenuColors =
            Css.batch
                [ backgroundColor <| hex colors.backgroundPrimary
                , borderColor <| hex colors.border
                ]
    in
    [ body
        [ backgroundColor <| hex colors.backgroundSecondary
        , Css.color <| hex colors.fontPrimary
        ]
    , a
        [ Css.color <| hex colors.link ]
    , class "menu"
        [ Css.hover [ activeMenuColors ]
        , focusWithin [ activeMenuColors ]
        ]
    , class "burger"
        [ backgroundColor <| hex colors.backgroundPrimary ]
    , class "burgerAlt"
        [ backgroundColor <| hex colors.backgroundSecondary ]
    , class "content"
        [ backgroundColor <| hex colors.backgroundPrimary ]
    , class "post-metadata"
        [ descendants
            [ a
                [ borderColor (hex colors.border)
                , backgroundColor <| hex colors.backgroundPrimary
                ]
            ]
        ]
    ]


styles : Html msg
styles =
    let
        activeMenuStyle =
            Css.batch
                [ Css.maxWidth none
                , Css.maxHeight none
                , borderRadius <| px 6
                ]
    in
    global
        (List.concat
            [ typography
            , theme
            , [ everything [ boxSizing borderBox ]
              , body
                    [ padding <| px 0
                    , margin <| px 0
                    ]
              , a [ textDecoration none ]
              , p [ margin3 auto auto (rem 1.5) ]
              , Css.Global.small [ fontSize <| pct 65 ]
              , class "burger"
                    [ Css.height <| px 6
                    , borderRadius <| px 3
                    , Css.width <| px 36
                    ]
              , class "burgerAlt"
                    [ Css.height <| px 6
                    , borderRadius <| px 3
                    , Css.width <| px 36
                    ]
              , class "menu"
                    [ position absolute
                    , top <| px 6
                    , left <| px 6
                    , padding <| px 6
                    , overflow hidden
                    , Css.maxWidth <| px 48
                    , Css.maxHeight <| px 48
                    , borderWidth <| px 2
                    , borderStyle solid
                    , borderColor transparent
                    , Css.hover [ activeMenuStyle ]
                    , focusWithin [ activeMenuStyle ]
                    , descendants
                        [ class "menuIcon"
                            [ outline none ]
                        , ul
                            [ listStyleType none
                            , margin <| px 0
                            , padding <| px 6
                            ]
                        ]
                    ]
              , class "content"
                    [ Css.maxWidth <| ch 65
                    , margin auto
                    , padding <| ch 3
                    , paddingTop <| px 42
                    , Css.minHeight <| vh 100
                    ]
              , class "post-metadata"
                    [ marginTop <| Css.em -0.5
                    , marginBottom <| Css.em 2.0
                    , descendants
                        [ each [ a, span ]
                            [ display inlineBlock
                            , marginRight <| px 5
                            ]
                        , a
                            [ border2 (px 1) solid
                            , borderRadius <| Css.em 0.3
                            , paddingLeft <| px 5
                            , paddingRight <| px 5
                            ]
                        ]
                    ]
              ]
            ]
        )
        |> Html.Styled.toUnstyled


focusWithin : List Style -> Style
focusWithin =
    pseudoClass "focus-within"
