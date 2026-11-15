using UnityEngine;

/// <summary>
/// Tworzy spiralna animacje swiecacych czasteczek wokol obiektu.
/// Cz?steczki poruszaja sie po torze spiralnym, unosza sie ku gorze
/// i pulsacyjnie zmieniaja swoj rozmiar.
/// </summary>
public class MagicSpiral : MonoBehaviour
{
    [Header("Referencje")]
    [SerializeField] private Transform player;
    [SerializeField] private Material particleMaterial;

    [Header("Parametry spirali")]
    [SerializeField, Min(1)] private int particleCount = 60;
    [SerializeField, Min(0.1f)] private float radius = 1.2f;
    [SerializeField, Min(0.5f)] private float height = 5f;
    [SerializeField, Min(0.1f)] private float rotationSpeed = 2f;
    [SerializeField, Min(0.1f)] private float upwardSpeed = 1.5f;
    [SerializeField, Min(0.01f)] private float particleSize = 0.07f;

    [Header("Aktywacja efektu")]
    [SerializeField, Min(0.1f)] private float activationDistance = 5f;
    [SerializeField] private bool alwaysActive = false;

    // Obiekt nadrzedny przechowujacy wszystkie wygenerowane czasteczki.
    private Transform particleRoot;

    // Tablica przechowujaca referencje do transformacji czasteczek.
    private Transform[] particles;

    // Indywidualne przesuniecia fazowe okreslajace polozenie czasteczek na spirali.
    private float[] offsets;

    // Informacja o aktualnym stanie aktywnosci efektu.
    private bool isActive;

    private void Start()
    {
        // Sprawdzenie, czy przypisano material wymagany do wyswietlenia czasteczek.
        if (particleMaterial == null)
        {
            Debug.LogError(
                "MagicSpiral: assign a material to Particle Material.",
                this
            );
            enabled = false;
            return;
        }

        // Utworzenie obiektu nadrzednego dla wszystkich elementow spirali.
        particleRoot = new GameObject("Generated Magic Spiral").transform;
        particleRoot.SetParent(transform, false);
        particleRoot.localPosition = Vector3.zero;

        // Przygotowanie tablic do przechowywania czasteczek i ich przesuniec fazowych.
        particles = new Transform[particleCount];
        offsets = new float[particleCount];

        for (int i = 0; i < particleCount; i++)
        {
            // Utworzenie pojedynczej czasteczki w ksztalcie kuli.
            GameObject particle = GameObject.CreatePrimitive(
                PrimitiveType.Sphere
            );

            particle.name = "Magic Particle " + i;
            particle.transform.SetParent(particleRoot, false);

            // Usuniecie collidera, poniewaz czasteczki pelnia wylacznie funkcje wizualna.
            Collider particleCollider =
                particle.GetComponent<Collider>();

            if (particleCollider != null)
                Destroy(particleCollider);

            // Przypisanie materialu oraz wylaczenie generowania i odbierania cieni.
            Renderer particleRenderer =
                particle.GetComponent<Renderer>();

            particleRenderer.sharedMaterial = particleMaterial;
            particleRenderer.shadowCastingMode =
                UnityEngine.Rendering.ShadowCastingMode.Off;
            particleRenderer.receiveShadows = false;

            // Zapisanie referencji i przypisanie rownomiernego przesuniecia fazowego.
            particles[i] = particle.transform;
            offsets[i] = (float)i / particleCount;

            // Ustawienie poczatkowego rozmiaru czasteczki.
            particle.transform.localScale =
                Vector3.one * particleSize;
        }

        // Ukrycie wszystkich czasteczek do momentu aktywacji efektu.
        SetParticlesVisible(false);
    }

    private void Update()
    {
        // Przerwanie aktualizacji, jesli nie przypisano gracza i efekt nie jest stale aktywny.
        if (player == null && !alwaysActive)
            return;

        // Ustalenie poczatkowego stanu aktywnosci na podstawie ustawien efektu.
        bool shouldBeActive = alwaysActive;

        if (player != null)
        {
            // Obliczenie odleglosci miedzy graczem a obiektem generujacym spirale.
            float distance = Vector3.Distance(
                player.position,
                transform.position
            );

            // Aktywacja efektu po zblizeniu sie gracza na okreslona odleglosc.
            shouldBeActive |= distance <= activationDistance;
        }

        // Aktualizacja widocznosci czasteczek tylko w przypadku zmiany stanu efektu.
        if (shouldBeActive != isActive)
        {
            isActive = shouldBeActive;
            SetParticlesVisible(isActive);
        }

        // Pominiecie obliczen animacji, gdy efekt jest nieaktywny.
        if (!isActive)
            return;

        for (int i = 0; i < particles.Length; i++)
        {
            // Wyznaczenie postepu ruchu czasteczki wzdluz wysokosci spirali.
            // Mathf.Repeat powoduje powrot czasteczki na poczatek po osiagnieciu gornego polozenia.
            float progress = Mathf.Repeat(
                offsets[i] + Time.time * upwardSpeed / height,
                1f
            );

            // Obliczenie kata obrotu z uwzglednieniem indywidualnego przesuniecia czasteczki.
            float angle =
                offsets[i] * Mathf.PI * 2f
                + Time.time * rotationSpeed;

            // Wyznaczenie wspolrzednych na okregu tworzacym poziomy przekroj spirali.
            float x = Mathf.Cos(angle) * radius;
            float z = Mathf.Sin(angle) * radius;

            // Wyznaczenie wysokosci czasteczki na podstawie postepu animacji.
            float y = progress * height;

            // Aktualizacja lokalnego polozenia czasteczki.
            particles[i].localPosition = new Vector3(x, y, z);

            // Obliczenie pulsacji rozmiaru za pomoca funkcji sinus.
            float pulse = 0.75f +
                0.25f * Mathf.Sin(Time.time * 4f + i);

            // Aktualizacja skali czasteczki w celu uzyskania efektu pulsowania.
            particles[i].localScale =
                Vector3.one * particleSize * pulse;
        }
    }

    private void SetParticlesVisible(bool visible)
    {
        // Zabezpieczenie przed odwolaniem do niezainicjalizowanej tablicy czasteczek.
        if (particles == null)
            return;

        // Wlaczenie lub wylaczenie wszystkich wygenerowanych czasteczek.
        foreach (Transform particle in particles)
        {
            if (particle != null)
                particle.gameObject.SetActive(visible);
        }
    }

    private void OnDestroy()
    {
        // Usuniecie obiektu nadrzednego wraz ze wszystkimi wygenerowanymi czasteczkami.
        if (particleRoot != null)
            Destroy(particleRoot.gameObject);
    }
}