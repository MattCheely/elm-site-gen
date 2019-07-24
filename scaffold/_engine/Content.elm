module Content exposing
    ( Content(..)
    , PageData
    , PostData
    , PostList
    , encode
    , pageDataDecoder
    , postDataDecoder
    , postListDecoder
    , postPath
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type Content
    = Post PostData
    | Page PageData
    | Posts PostList
    | TagIndex String PostList
    | Static String String


type alias PostList =
    { posts : List PostData
    , title : String
    }


type alias PostData =
    { date : String
    , content : String
    , tags : List String
    , title : String
    , slug : String
    }


type alias PageData =
    { content : String
    , title : String
    , slug : String
    }



{- TODO: Create a type that represents the JS content contract:
   layout, outputPath, whateverData
   "Static" is a special layout
-}


encode : Content -> Value
encode pageType =
    case pageType of
        Post postData ->
            Encode.object
                [ ( "layout", Encode.string "Post" )
                , ( "data", encodePostData postData )
                ]

        Page pageData ->
            Encode.object
                [ ( "layout", Encode.string "Page" )
                , ( "data", encodePageData pageData )
                ]

        Posts postList ->
            Encode.object
                [ ( "layout", Encode.string "Posts" )
                , ( "data", encodePostList "index.html" postList )
                ]

        TagIndex tag posts ->
            Encode.object
                [ ( "layout", Encode.string "Tag" )
                , ( "data", encodePostList ("tags/" ++ tag ++ "/index.html") posts )
                ]

        Static src dest ->
            Encode.object
                [ ( "layout", Encode.string "Static" )
                , ( "sourcePath", Encode.string src )
                , ( "destPath", Encode.string dest )
                ]


postPath : PostData -> String
postPath postData =
    "posts/" ++ postData.slug ++ "/"


encodePostData : PostData -> Value
encodePostData postData =
    Encode.object
        [ ( "date", Encode.string postData.date )
        , ( "content", Encode.string postData.content )
        , ( "tags", Encode.list Encode.string postData.tags )
        , ( "title", Encode.string postData.title )
        , ( "slug", Encode.string postData.slug )
        , ( "outputPath", Encode.string (postPath postData ++ "index.html") )
        ]


postDataDecoder : Decoder PostData
postDataDecoder =
    Decode.map5 PostData
        (Decode.field "date" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "tags" <| Decode.list Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "slug" Decode.string)


encodePostList : String -> PostList -> Value
encodePostList outputPath postList =
    Encode.object
        [ ( "title", Encode.string postList.title )
        , ( "posts", Encode.list encodePostData postList.posts )
        , ( "outputPath", Encode.string outputPath )
        ]


postListDecoder : Decoder PostList
postListDecoder =
    Decode.map2 PostList
        (Decode.field "posts" (Decode.list postDataDecoder))
        (Decode.field "title" Decode.string)


encodePageData : PageData -> Value
encodePageData pageData =
    Encode.object
        [ ( "title", Encode.string pageData.title )
        , ( "content", Encode.string pageData.content )
        , ( "slug", Encode.string pageData.slug )
        , ( "outputPath", Encode.string (pageData.slug ++ "/index.html") )
        ]


pageDataDecoder : Decoder PageData
pageDataDecoder =
    Decode.map3 PageData
        (Decode.field "content" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "slug" Decode.string)
