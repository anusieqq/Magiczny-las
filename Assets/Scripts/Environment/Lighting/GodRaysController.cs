using UnityEngine;

/// <summary>
/// Aktualizuje ekranowe polozenie swiatla kierunkowego
/// oraz kontroluje plynna zmiane intensywnosci efektu promieni swietlnych.
/// </summary>
[ExecuteAlways]
public class GodRaysController : MonoBehaviour
{
    public Camera targetCamera;
    public Light directionalLight;
    public Material godRaysMaterial;

    [Header("Wyg?adzanie")]
    [Range(0.1f, 5f)]
    public float smoothSpeed = 1.5f;

    [Header("Widocznosc efektu")]
    [Range(0f, 1f)]
    public float minimumIntensity = 0.2f;

    // Identyfikator parametru shadera przechowujacego ekranowa pozycje swiatla.
    private static readonly int LightScreenPos =
        Shader.PropertyToID("_LightScreenPos");

    // Identyfikator parametru shadera kontrolujacego intensywnosc promieni.
    private static readonly int RayIntensity =
        Shader.PropertyToID("_RayIntensity");

    // Aktualna intensywnosc efektu wykorzystywana do stopniowego wygladzania zmian.
    private float currentIntensity;

    private void LateUpdate()
    {
        // Pominiecie aktualizacji, jesli nie przypisano wymaganych referencji.
        if (targetCamera == null ||
            directionalLight == null ||
            godRaysMaterial == null)
            return;

        // Wyznaczenie kierunku padania swiatla kierunkowego.
        Vector3 lightDirection =
            -directionalLight.transform.forward;

        // Utworzenie odleglego punktu reprezentujacego polozenie zrodla swiatla.
        Vector3 lightPoint =
            targetCamera.transform.position + lightDirection * 1000f;

        // Przeksztalcenie pozycji swiatla ze wspolrzednych swiata
        // na wspolrzedne obszaru widoku kamery.
        Vector3 screenPosition =
            targetCamera.WorldToViewportPoint(lightPoint);

        // Ograniczenie pozycji swiatla do rozszerzonego obszaru widoku,
        // aby uniknac naglych zmian efektu przy krawedziach ekranu.
        float x = Mathf.Clamp(screenPosition.x, -1f, 2f);
        float y = Mathf.Clamp(screenPosition.y, -1f, 2f);

        // Wylaczenie wplywu swiatla, gdy znajduje sie za kamera.
        float frontFactor = screenPosition.z > 0f ? 1f : 0f;

        // Obliczenie intensywnosci efektu na podstawie wysokosci swiatla
        // w obszarze widoku kamery.
        float heightFactor = Mathf.InverseLerp(0.0f, 0.8f, y);

        // Wyg?adzenie przejscia miedzy kolejnymi poziomami intensywnosci.
        heightFactor = Mathf.SmoothStep(0f, 1f, heightFactor);

        // Wyznaczenie docelowej intensywnosci z uwzglednieniem minimalnej wartosci.
        float targetIntensity =
            minimumIntensity +
            heightFactor * (1f - minimumIntensity);

        // Uwzglednienie widocznosci swiatla wzgledem kamery.
        targetIntensity *= frontFactor;

        // Przekazanie ekranowej pozycji swiatla do shadera.
        // Shader wykorzystuje te wspolrzedne do wyznaczania kierunku promieni.
        godRaysMaterial.SetVector(
            LightScreenPos,
            new Vector4(x, y, 0f, 1f)
        );

        // Zabezpieczenie predkosci wygladzania przed wartoscia zerowa lub ujemna.
        float speed = Mathf.Max(0.01f, smoothSpeed);

        // Stopniowe dopasowanie aktualnej intensywnosci do wartosci docelowej.
        // Zastosowanie funkcji wykladniczej zapewnia niezalezne od FPS wygladzanie zmian.
        currentIntensity = Mathf.Lerp(
            currentIntensity,
            targetIntensity,
            1f - Mathf.Exp(-speed * Time.deltaTime)
        );

        // Przekazanie aktualnej intensywnosci efektu do shadera.
        godRaysMaterial.SetFloat(
            RayIntensity,
            currentIntensity
        );
    }
}