using UnityEngine;

/// <summary>
/// Uruchamia animacje fali swietlnej na drzewie po zblizeniu sie gracza.
/// Efekt jest realizowany przez aktualizacje parametrow shadera.
/// </summary>
public class MagicTreeActivation : MonoBehaviour
{
    [Header("Referencje")]
    [SerializeField] private Transform player;
    [SerializeField] private Renderer[] treeRenderers;

    [Header("Parametry aktywacji")]
    [SerializeField, Min(0.1f)] private float activationDistance = 4f;
    [SerializeField, Min(0.1f)] private float waveSpeed = 3f;
    [SerializeField, Min(0.1f)] private float treeHeight = 6f;
    [SerializeField, Min(0f)] private float glowDuration = 2f;

    // Blok wlasciwosci materialu przechowujacy indywidualne parametry shadera.
    private MaterialPropertyBlock block;

    // Aktualna wysokosc przemieszczajacej sie fali swietlnej.
    private float waveHeight;

    // Pozostaly czas trwania efektu podswietlenia.
    private float glowTimer;

    // Informacja o aktualnym stanie animacji drzewa.
    private bool active;

    // Identyfikator parametru shadera okreslajacego aktualna wysokosc fali.
    private static readonly int WaveHeightID =
        Shader.PropertyToID("_WaveHeight");

    // Identyfikator parametru shadera kontrolujacego intensywnosc efektu.
    private static readonly int ActivationID =
        Shader.PropertyToID("_Activation");

    private void Awake()
    {
        // Utworzenie bloku wlasciwosci do przekazywania parametrow shaderowi.
        block = new MaterialPropertyBlock();

        // Automatyczne pobranie rendererow z obiektu i jego obiektow potomnych,
        // jesli nie przypisano ich recznie w Inspectorze.
        if (treeRenderers == null || treeRenderers.Length == 0)
            treeRenderers = GetComponentsInChildren<Renderer>();
    }

    private void Update()
    {
        // Pominiecie aktualizacji, jesli nie przypisano obiektu gracza.
        if (player == null)
            return;

        // Obliczenie odleglosci miedzy graczem a drzewem.
        float distance = Vector3.Distance(
            player.position,
            transform.position
        );

        // Rozpoczecie animacji po wejsciu gracza w zasieg aktywacji.
        if (!active && distance <= activationDistance)
        {
            active = true;

            // Ustawienie poczatkowej wysokosci fali na poziomie podstawy drzewa.
            waveHeight = transform.position.y;

            // Inicjalizacja czasu trwania efektu podswietlenia.
            glowTimer = glowDuration;
        }

        // Zatrzymanie dalszych obliczen, jesli animacja nie jest aktywna.
        if (!active)
            return;

        // Przesuwanie fali swietlnej ku gorze z uwzglednieniem czasu klatki.
        waveHeight += waveSpeed * Time.deltaTime;

        // Aktualizacja pozostalego czasu trwania efektu.
        glowTimer -= Time.deltaTime;

        // Normalizacja czasu trwania efektu do zakresu od 0 do 1.
        // Wartosc ta steruje intensywnoscia podswietlenia w shaderze.
        float activation = Mathf.Clamp01(
            glowTimer / Mathf.Max(glowDuration, 0.01f)
        );

        foreach (Renderer treeRenderer in treeRenderers)
        {
            // Pominiecie elementow, ktore zostaly usuniete ze sceny.
            if (treeRenderer == null)
                continue;

            // Pobranie aktualnych nadpisanych wlasciwosci renderera.
            // Pozwala zachowac pozostale parametry bez tworzenia instancji materialu.
            treeRenderer.GetPropertyBlock(block);

            // Przekazanie aktualnej wysokosci fali i intensywnosci efektu do shadera.
            block.SetFloat(WaveHeightID, waveHeight);
            block.SetFloat(ActivationID, activation);

            // Zastosowanie zaktualizowanych parametrow do renderera.
            treeRenderer.SetPropertyBlock(block);
        }

        // Zakonczenie animacji po przekroczeniu przez fale gornego zakresu drzewa.
        if (waveHeight > transform.position.y + treeHeight)
        {
            active = false;

            foreach (Renderer treeRenderer in treeRenderers)
            {
                if (treeRenderer == null)
                    continue;

                // Pobranie aktualnych wlasciwosci renderera przed ich modyfikacja.
                treeRenderer.GetPropertyBlock(block);

                // Wylaczenie efektu i ustawienie wysokosci fali poza zakresem drzewa.
                block.SetFloat(ActivationID, 0f);
                block.SetFloat(WaveHeightID, -100f);

                // Zastosowanie koncowych parametrow shadera.
                treeRenderer.SetPropertyBlock(block);
            }
        }
    }
}