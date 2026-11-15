using UnityEngine;

/// <summary>
/// Odpowiada za animacje krysztalu poprzez plynny ruch pionowy
/// oraz opcjonalny obrot wokol lokalnej osi Y.
/// </summary>
public class CrystalFloat : MonoBehaviour
{
    [Header("Animacja unoszenia")]
    [SerializeField] private float amplitude = 0.2f;
    [SerializeField] private float frequency = 0.8f;

    [Header("Opcjonalny obrot")]
    [SerializeField] private bool rotate = true;
    [SerializeField] private float rotationSpeed = 10f;

    // Poczatkowa pozycja obiektu wykorzystywana jako punkt odniesienia animacji.
    private Vector3 startPosition;

    // Losowe przesuniecie fazowe zapobiegajace jednoczesnemu ruchowi wszystkich krysztalow.
    private float randomOffset;

    private void Start()
    {
        // Zapisanie poczatkowej pozycji lokalnej obiektu.
        startPosition = transform.localPosition;

        // Wylosowanie przesuniecia fazowego dla zroznicowania animacji.
        randomOffset = Random.Range(0f, Mathf.PI * 2f);
    }

    private void Update()
    {
        // Obliczenie okresowego przesuniecia pionowego z wykorzystaniem funkcji sinus.
        // Czestotliwosc okresla tempo ruchu, a amplituda jego maksymalna wysokosc.
        float offsetY = Mathf.Sin(
            Time.time * frequency * 2f * Mathf.PI + randomOffset
        ) * amplitude;

        // Aktualizacja pozycji obiektu wzgledem jego pozycji poczatkowej.
        transform.localPosition = startPosition
                                + Vector3.up * offsetY;

        // Obracanie krysztalu wokol lokalnej osi Y, jesli opcja jest wlaczona.
        if (rotate)
        {
            transform.Rotate(
                Vector3.up,
                rotationSpeed * Time.deltaTime,
                Space.Self
            );
        }
    }
}