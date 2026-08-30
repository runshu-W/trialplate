\name{plate_legend}
\alias{plate_legend}
\title{Legend for the criteria plate plot}
\usage{
plate_legend(scU, scL, cex = 0.62)
}
\arguments{
  \item{scU}{Upper-triangle radius scale.}
  \item{scL}{Lower-triangle radius scale.}
  \item{cex}{Base text size.}
}
\description{
Draws the plate anatomy, the adjusted-q colour bands, the two hatch meanings and the diagonal cost ramp. Intended for its own device region via \code{layout}.
}
\value{
Invisibly NULL, called for its side effect.
}
