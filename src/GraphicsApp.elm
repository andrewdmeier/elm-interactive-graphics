module GraphicsApp
    exposing
        ( Drawing
        , draw
        , Animation
        , animate
        , Time
        , Simulation
        , simulate
        , Interaction
        , interact
        , Msg(..)
        )

{-| Incremental introduction to interactive graphics programs.

# Draw
@docs Drawing, draw

# Draw with Time
@docs Animation, animate, Time

# Draw with Time and Model
@docs Simulation, simulate

# Draw with Model and Messages
@docs Interaction, interact, Msg
-}

import AnimationFrame
import Element exposing (toHtml)
import Html
import Html.Lazy exposing (lazy)
import Mouse


{-| -}
type alias Time =
    Float


{-| -}
type Msg
    = TimeTick Time
    | MouseClick


type TimeMsg
    = Diff Time


{-| -}
type alias Drawing =
    Program Never () Never


{-| -}
type alias Animation =
    Program Never Time TimeMsg


{-| -}
type alias Simulation model =
    Program Never ( Time, model ) TimeMsg


{-| -}
type alias Interaction model =
    Program Never ( Time, model ) Msg


{-| -}
draw : Element.Element -> Drawing
draw view =
    Html.program
        { init = () ! []
        , view = \_ -> toHtml view
        , update = \_ model -> model ! []
        , subscriptions = \_ -> Sub.none
        }


{-| -}
animate : (Time -> Element.Element) -> Animation
animate view =
    Html.program
        { init = 0 ! []
        , view = \time -> toHtml (view time)
        , update = \(Diff diff) time -> (time + diff) ! []
        , subscriptions = \_ -> AnimationFrame.diffs Diff
        }


{-| -}
simulate :
    model
    -> (model -> Element.Element)
    -> (Time -> model -> model)
    -> Simulation model
simulate init view update =
    Html.program
        { init = ( 0, init ) ! []
        , view = \( _, model ) -> lazy (view >> toHtml) model
        , update = simulationUpdate update
        , subscriptions = \_ -> AnimationFrame.diffs Diff
        }


simulationUpdate :
    (Time -> model -> model)
    -> TimeMsg
    -> ( Time, model )
    -> ( ( Time, model ), Cmd TimeMsg )
simulationUpdate update (Diff diff) ( time, model ) =
    let
        updatedTime =
            time + diff

        newModel =
            update updatedTime model

        updatedModel =
            -- necessary for lazy
            if newModel == model then
                model
            else
                newModel
    in
        ( updatedTime, updatedModel ) ! []


{-| -}
interact :
    model
    -> (model -> Element.Element)
    -> (Msg -> model -> model)
    -> Interaction model
interact init view update =
    Html.program
        { init = ( 0, init ) ! []
        , view = \( _, model ) -> lazy (view >> toHtml) model
        , update = interactionUpdate update
        , subscriptions = interactionSubscriptions
        }


interactionUpdate :
    (Msg -> model -> model)
    -> Msg
    -> ( Time, model )
    -> ( ( Time, model ), Cmd Msg )
interactionUpdate update msg ( time, model ) =
    case msg of
        TimeTick diff ->
            let
                updatedTime =
                    time + diff

                newModel =
                    update (TimeTick updatedTime) model

                updatedModel =
                    -- necessary for lazy
                    if newModel == model then
                        model
                    else
                        newModel
            in
                ( updatedTime, updatedModel ) ! []

        _ ->
            let
                newModel =
                    update msg model

                updatedModel =
                    -- necessary for lazy
                    if newModel == model then
                        model
                    else
                        newModel
            in
                ( time, updatedModel ) ! []


interactionSubscriptions : ( Time, model ) -> Sub Msg
interactionSubscriptions _ =
    Sub.batch
        [ AnimationFrame.diffs TimeTick
        , Mouse.clicks (\_ -> MouseClick)
        ]
