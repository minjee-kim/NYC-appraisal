# NYC appraisal filter

A Bayesian state-space model for New York City class 1 property values. The Department of Finance appraisal is a lagged, censored measurement of a latent price. The project recovers that price.

## Data

Class 1 final assessment rolls, fiscal 2009 through 2026, from the [NYC Department of Finance assessment roll archives](https://www.nyc.gov/site/finance/property/property-assessment-roll-archives.page). Each row is one tax lot in one fiscal year. Market land value and market total value are the two appraisal measurements. Deed sales, joined later on borough, block, and lot, are the transaction prices.

The rolls are public. The raw files are not in this repository.

## Censoring

After 2009 the total appraisal cannot rise past a statutory cap, so a large price increase is only partly recorded. Assessed land value is not under that cap. A capped total is therefore a censored observation: the reported number is not the appraisal the assessor would have filed, and it is not the building price.

The censored outcome is the unobserved appraisal update. It is not imputed from the capped series. It is estimated from the latent price, and the latent price is identified by deed sales of the same buildings and by the land value, which is allowed to move.

## Model

Let $P_t$ be the latent building price, $A_t^*$ the appraisal that would have been filed without the cap, and $A_t$ the appraisal on the roll. Land value is $L_t$. A sale $S_t$ is observed only when the lot transacts.

$$
\begin{align}
P_t &= P_{t-1} + w_t \\
A_t^* &= \alpha P_t + (1-\alpha) A_{t-1} + e_t \\
A_t &= \min(A_t^*, c_t) \\
L_t &= P_t + u_t \\
S_t &= P_t + v_t \quad \text{when the building sells}
\end{align}
$$

$c_t$ is the cap. $\alpha$ is the share of the gap the appraisal closes. When $A_t = c_t$, the observation is an inequality, $A_t^* \ge c_t$, not a point. The filter estimates $P_t$ and the censored $A_t^*$ from the land measurement and from $S_t$.

## References

The desmoothing papers below invert a smoothed index. This project writes that smoothing as the observation equation instead.

- Geltner, David. 1991. "Smoothing in Appraisal-Based Returns." *Journal of Real Estate Finance and Economics* 4: 327–345. https://doi.org/10.1007/BF00161933
- Geltner, David. 1993. "Estimating Market Values from Appraised Values without Assuming an Efficient Market." *Journal of Real Estate Research* 8 (3): 325–345. https://doi.org/10.1080/10835547.1993.12090713
- Fisher, Jeffrey D., David M. Geltner, and R. Brian Webb. 1994. "Value Indices of Commercial Real Estate: A Comparison of Index Construction Methods." *Journal of Real Estate Finance and Economics* 9: 137–164. https://doi.org/10.1007/BF01099972
- Getmansky, Mila, Andrew W. Lo, and Igor Makarov. 2004. "An Econometric Model of Serial Correlation and Illiquidity in Hedge Fund Returns." *Journal of Financial Economics* 74 (3): 529–609. https://doi.org/10.1016/j.jfineco.2003.09.005
- Couts, Spencer, Andrei S. Gonçalves, and Andrea Rossi. 2024. "Unsmoothing Returns of Illiquid Funds." *Review of Financial Studies* 37 (7): 2110–2151. https://doi.org/10.1093/rfs/hhae006
