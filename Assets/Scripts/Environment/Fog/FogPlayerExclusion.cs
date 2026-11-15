using UnityEngine;

/// <summary>
/// Przekazuje pozycje gracza do shadera mgly,
/// umozliwiajac utworzenie obszaru wylaczenia efektu wokol gracza
/// bez tworzenia dodatkowej instancji materialu.
/// </summary>
[RequireComponent(typeof(Renderer))]
public class FogPlayerExclusion : MonoBehaviour
{
    [Header("Gracz")]
    [SerializeField] private Transform player;

    // Referencja do renderera odpowiedzialnego za wyswietlanie efektu mgly.
    private Renderer fogRenderer;

    // Blok wlasciwosci przechowujacy indywidualne parametry przekazywane do shadera.
    private MaterialPropertyBlock properties;

    // Identyfikator parametru shadera przechowujacego pozycje gracza.
    private static readonly int PlayerPositionID =
        Shader.PropertyToID("_PlayerPosition");

    private void Awake()
    {
        // Pobranie renderera obiektu i utworzenie bloku wlasciwosci materialu.
        fogRenderer = GetComponent<Renderer>();
        properties = new MaterialPropertyBlock();
    }

    private void LateUpdate()
    {
        // Pomini?cie aktualizacji, jesli nie przypisano gracza lub renderera.
        if (player == null || fogRenderer == null)
            return;

        // Pobranie aktualnej pozycji gracza w przestrzeni swiata.
        Vector3 playerPosition = player.position;

        // Odczytanie aktualnych wlasciwosci renderera w celu zachowania pozostalych parametrow.
        fogRenderer.GetPropertyBlock(properties);

        // Przekazanie pozycji gracza do parametru shadera w postaci wektora.
        properties.SetVector(
            PlayerPositionID,
            new Vector4(
                playerPosition.x,
                playerPosition.y,
                playerPosition.z,
                1f
            )
        );

        // Aktualizacja wlasciwosci renderera bez tworzenia nowej instancji materialu.
        fogRenderer.SetPropertyBlock(properties);
    }
}